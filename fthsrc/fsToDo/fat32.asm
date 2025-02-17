;********************************************
; FAT32
;	Reading from a FAT32 filesystem on a hard-disk
;
;
;	Modified FAT32: 
;		- there is one FAT
;		- the Dir-entry is different! (takes 32-bytes, name: len+max16chars)
;		- end-of-cluster-marker is 0xFFFFFFFF
;		- bad-sector is 0xFFFFFFF7 but it is not used
;		- higher 4 bits of cluster-number is not reserved
;		- there is no need for Unicode-char substitution as in usbfat32!
;		- ATTRIB-bits!?
;		- Error handling!? (if writing to FAT or clusters fail)
;		- Size in a dir-entry is for files and directories but during read the size is not used.
;			e.g. a directory is read cluster-by-cluster (in case of a file the size is not used too)
;			However during read we do it cluster-by-cluster (getnextclus) and size is not used
;		- '.' and ".." are not added to normal dirs 
;			(we have two arrays: the first is the index-array(i.e. integers) into the second one, which array is the clusternum array)
;		- No copy of VBR and FSInfo sectors
;		- Multitasking: a task should call fat32_save_path before changing directories; when finished the task should call fat32_restore_path
;
;********************************************


; Modified FAT32
;	In the MBR from byte 446 (0x01BE) there are four 16-byte partition entries. 
;	A partition-entry:
;	BootFlag(byte0), CHSBegin(byte1-3), TypeCode(byte4), CHSEnd(byte5-7), LBABegin(byte8-11), NumberOfSectors(byte12-15)
;	Type code indicates the type of the filesystem (0x0B and 0x0C are used for FAT32). 
;	LBABegin tells us where the FAT32 filesystem begins on the disk. This first sector is called the VolumeID.
;	The VolumeID contains info about the physical layout of the FAT32 filesystem.
;	VolumeID (name, offset, size(bits), value):
;		Bytes Per Sector		- 0x0B - 16 - Always 512
;		Sectors Per Cluster		- 0x0D -  8 - 1,2,4,8,16,32,64,128
;		Num of Reserved Sectors - 0x0E - 16 - Usually 0x20
;		Number of FATs			- 0x10 -  8 - Always 2
;		Sectors Per FAT			- 0x24 - 32 - Depends on disk size
;		Root Dir 1st Cluster	- 0x2C - 32 - Usually 0x00000002
;		Signature				- 0x1FE - 16 - Always 0xAA55
;	Check BytesPerSectors, NumberOfFATs and the Signiture to see if it's really a FAT32.
;
;	fat_begin_lba(DWORD)			= Partition_LBA_begin + Number_Of_Reserved_Sectors
;	cluster_begin_lba(DWORD)		= Partition_LBA_begin + Number_Of_Reserved_Sectors + (Number_Of_FATs * Sectors_Per_FAT)
;	sectors_per_cluster(BYTE)		= Sectors Per Cluster
;	root_dir_first_cluster(DWORD)	= Root Dir First Cluster
;
;	So, there is the VolumeID followed by the ReservedSectors and then do the 2 FATs come. 
;	Next come the Clusters(Files and Dirs) perhaps followed by a small UnusedSpace. The clusters begin their numbering at 2 (no 0 and 1).
;
;	lba_addr = cluster_begin_lba + (cluster_number - 2) * sectors_per_clusters
;
;	The RootDir reveals the names and the first cluster location of the files and subdirs (filelength, time, etc. is also included).
;	FAT contains the rest of the cluster addresses.
;	Directory data is organized in 32-byte records. There are 3 types:
;		1. Normal record with a 17-byte long filename (first byte is length) (Attrib is normal)
;		2. Unused (first byte is 0xE5) ; result of deletion (only in a Dir-Entry, not in FAT-table)
;		3. End of directory (first byte is zero)
;
; 	Dir-Entry (DE):
;	Filename			0	; 17 bytes (1st byte is length)
;	Attrib				17	; 1 byte
;	Date of creation	18	; 2 bytes	[Year(7), Mon(4), Day(5)]
;	Date of last access	20	; 2 bytes	[Year(7), Mon(4), Day(5)]
;	Date of write		22	; 2 bytes	[Year(7), Mon(4), Day(5)]
;	Cluster number		24	; 4 bytes
;	Filesize			28	; 4 bytes
;
;	Attrib-byte:
;		0	-	Read-only	(not allow writing)		[LSB]
;		1	-	Hidden		(don't show)
;		2	-	System		(fille is OS)
;		3	-	VolumeID	(Filename is VolumeID)
;		4	-	Directory	(it's a subdir)
;		5	-	Archive		(changed since last backup)
;		6	-	Unused		(should be zero)
;		7	-	Unused		(should be zero)
;		In case of a LongFilename attrib-byte=00xx1111b
;
;	Following Cluster Chains:
;		The directory entry tells us only the first cluster of each file (or subdir). To access all the other clusters of a file 
;		beyond the first cluster, you need to use the FAT. Each entry in the FAT is 32-bits.
;		Every sector holds 128 32-bit entries in the FAT. Bits 7-31 of the current cluster tell you which sectors to read from the FAT, 
;		and bits 0-6 tell you which of the 128 entries in that sector is the number of the next cluster of the file.
;		For example a file has the cluster number 0x00000002 in the directory record. We look at the 3rd (0, 1, 2) entry in the FAT and 
;		find 0x00000009. The 10th entry contains 0x0000000A. The 11th entry is 0x0000000B, the 12th is 0x00000011. The 18th is 0xFFFFFFF8.
;		So the file consist of clusters 2, 9, A, B, 11. End of file maker: greater or equal to 0xFFFFFFF8.
;		According to the specs, the cluster numbers use only the lower 28-bits, the remaining 4 bits are reserved and should be masked.
;		Files that have zero length, have cluster 0 in the directory-record. Zeros in the FAT mark clusters that are free space.
;		
;	In every folder(i.e. directory) except the root, there are '.' and '..' (pointer to itself; pointer to the parent)
;		
;	FSInfo (Offs, Len):
;		0x0000	4		FS information sector signature (0x52 0x52 0x61 0x41 = "RRaA")  
;		0x0004	480		Reserved (byte values should be set to 0x00 during format, but not be relied upon and never changed later on) 
;		0x01E4	4		FS information sector signature (0x72 0x72 0x41 0x61 = "rrAa") 
;		0x01E8	4		Last known number of free data clusters on the volume, or 0xFFFFFFFF if unknown. 
;						Should be set to 0xFFFFFFFF during format and updated by the operating system later on. 
;						Must not be absolutely relied upon to be correct in all scenarios. Before using this value, 
;						the operating system should sanity check this value to be less than or equal to the volume's count of clusters. 	
;		0x01EC	4		NOTE! Unlike wikipedia, FAT32-specification says next-free-cluster!
;						But it is OK, because the search will start from this last allocated clusternum!!
;						Number of the most recently known to be allocated data cluster. Should be set to 0xFFFFFFFF during format 
;						and updated by the operating system later on. With 0xFFFFFFFF the system should start at cluster 0x00000002. 
;						Must not be absolutely relied upon to be correct in all scenarios. Before using this value, the operating system 
;						should sanity check this value to be a valid cluster number on the volume. 
;		0x01F0	12		Reserved (byte values should be set to 0x00 during format, but not be relied upon and never changed later on) 
;		0x01FC	4		FS information sector signature (0x00 0x00 0x55 0xAA) (All four bytes should match before the contents of this 
;						sector should be assumed to be in valid format.) 


%ifndef __FAT32__
%define __FAT32__


%include "hd.asm"
%include "gstdio.asm"
%include "gutil.asm"


%define FAT32_PATH_BUFF		0x6C0000
%define FAT32_NAME_BUFF		0x6C2000
%define FAT32_SECTOR_BUFF	0x6D0000						; for reading/writing sectors from/to FAT
%define FAT32_CLUSTER_BUFF	0x6E0000

; partition
%define	FAT32_PARTITION_TABLE_OFFS		0x01BE	; 446
%define	FAT32_TYPE_CODE1				0x0B
%define	FAT32_TYPE_CODE2				0x0C

; VolumeID
%define	FAT32_BYTES_PER_SECTOR_OFFS			0x0B
;%define	FAT32_SECTORS_PER_CLUSTER_OFFS	0x0D
;%define	FAT32_RESERVED_SECTORS_NUM_OFFS	0x0E
;%define	FAT32_FATS_NUM_OFFS				0x10
%define	FAT32_SECTORS_PER_FAT_OFFS			0x24
%define	FAT32_ROOT_DIR_CLUSTER_OFFS			0x2C
%define	FAT32_FSINFO_SECTOR_OFFS			0x30
%define	FAT32_COPY_BOOTSECTOR_CLUSTER_OFFS	0x32
%define	FAT32_SIGNATURE_OFFS				0X1FE

%define FAT32_DIR_ENTRY_LEN	32	; bytes

%define	FAT32_BYTES_SECTOR	512

%define FAT32_END_OF_CLUSTER_MARKER	0xFFFFFFFF
%define FAT32_BAD_SECTOR			0xFFFFFFF7
%define FAT32_DELETED_ENTRY			0xE5					; Used only in a Dir-Entry, not in FAT-table

; Masks(FAT-table)
%define FAT32_OFFSET_WITHIN_SECTOR_MASK	0x0000007F			; lower 7 bits is the offset within sector in the FAT

%define FAT32_MAX_NAME_LEN	17

; Dir-Entry (DE)
FAT32_DE_NAME		equ	0	; 17 bytes (1st byte is length)
FAT32_DE_ATTRIB		equ	17	; 1 byte
FAT32_DE_DATE_CR	equ	18	; 2 bytes	[Year(7), Mon(4), Day(5)]
FAT32_DE_DATE_LAST	equ	20	; 2 bytes	[Year(7), Mon(4), Day(5)]	; Last Access
FAT32_DE_DATE_WR	equ	22	; 2 bytes	[Year(7), Mon(4), Day(5)]
FAT32_DE_CLUS_NUM	equ	24	; 4 bytes	[first cluster number]
FAT32_DE_SIZE	equ	28	; 4 bytes

; Attrib
%define FAT32_ATTR_READONLY		1
%define FAT32_ATTR_HIDDEN		2
%define FAT32_ATTR_SYSTEM		4
%define FAT32_ATTR_VOLUMEID		8
%define FAT32_ATTR_DIRECTORY	16
%define FAT32_ATTR_ARCHIVE		32

; Attrib bits
;%define FAT32_ATTR_READONLY_BIT		0
;%define FAT32_ATTR_HIDDEN_BIT		1
;%define FAT32_ATTR_SYSTEM_BIT		2
;%define FAT32_ATTR_VOLUMEID_BIT		3
;%define FAT32_ATTR_DIRECTORY_BIT	4
;%define FAT32_ATTR_ARCHIVE_BIT		5

%define FAT32_MAX_DIR_DEPTH_NUM	7	; max. directory depth (can cd till that depth)	

%define FAT32_ROOTDIR_CHAR				'/'
%define FAT32_PATH_SEPARATOR_CHAR		'/'
%define FAT32_DATE_SEPARATOR_CHAR		'/'

; FSInfo
%define	FAT32_FSINFO_LEADSIG					0x41615252
%define	FAT32_FSINFO_STRUCSIG					0x61417272
%define	FAT32_FSINFO_TRAILSIG					0xAA550000
%define	FAT32_FSINFO_LEADSIG_OFFS				0
%define	FAT32_FSINFO_STRUCSIG_OFFS				484
%define	FAT32_FSINFO_FREECLUSTERCNT_OFFS		488
%define	FAT32_FSINFO_NEXTFREECLUSTERNUM_OFFS	492			; in reality this is the lastwritten-clusternum (the search starts from)
%define	FAT32_FSINFO_TRAILSIG_OFFS				508
%define	FAT32_FSINFO_UNKNOWN					0xFFFFFFFF

; BPB offsets
%define FAT32_BPBOEM_OFFS					(0+3)
%define FAT32_BPBBYTESPERSECTOR_OFFS		(8+3)
%define FAT32_BPBSECTORSPERCLUSTER_OFFS		(10+3)		; FILL BY FSFORMAT
%define FAT32_BPBRESERVEDSECTORS_OFFS		(11+3)
%define FAT32_BPBNUMBEROFFATS_OFFS			(13+3)
%define FAT32_BPBROOTENTRIES_OFFS			(14+3)
%define FAT32_BPBTOTALSECTORS_OFFS			(16+3)
%define FAT32_BPBMEDIA_OFFS					(18+3)
%define FAT32_BPBSECTORSPERFATW_OFFS	 	(19+3)
%define FAT32_BPBSECTORSPERTRACK_OFFS		(21+3)
%define FAT32_BPBHEADSPERCYLINDER_OFFS		(23+3)
%define FAT32_BPBHIDDENSECTORS_OFFS			(25+3)
%define FAT32_BPBLARGETOTALSECTORS_OFFS		(29+3)		; FILL BY FSFORMAT
%define FAT32_BPBSECTORSPERFAT_OFFS			(33+3)		; FILL BY FSFORMAT
%define FAT32_BPBMIRRORINGFLAGS_OFFS	 	(37+3)
%define FAT32_BPBVERSION_OFFS				(39+3)
%define FAT32_BPBROOTDIRCLUSTER_OFFS	 	(41+3)
%define FAT32_BPBLOCATIONFSINFSECTOR_OFFS	(45+3)
%define FAT32_BPBLOCATIONBACKUPSECTOR_OFFS	(47+3)
%define FAT32_BPBRESERVEDBOOTFNAME_OFFS		(49+3)
%define FAT32_BPBPHYSDRIVENUM_OFFS			(61+3)
%define FAT32_BPBFLAGS_OFFS					(62+3)
%define FAT32_BPBEXTENDEDBOOTSIG_OFFS		(63+3)
%define FAT32_BPBVOLUMESERIALNUM_OFFS		(64+3)
; DOS 7.1 Extended BPB (79 bytes, without bpbOEM)
%define FAT32_BPBVOLUMELABEL_OFFS			(68+3)
%define FAT32_BPBFSTYPE_OFFS			 	(79+3)

;MBR
%define FAT32_MBR_PE1_OFFS			446
%define FAT32_MBR_PE1_LBA_OFFS		(FAT32_MBR_PE1_OFFS+8)
%define FAT32_MBR_PE1_SECTORS_OFFS	(FAT32_MBR_PE1_OFFS+12)


section .text

; reads partition-table in MBR, and VolumeID-lba from it.
; Fills variables from VolumeID
; IN: -
; OUT: fat32_res (0 faliure)
fat32_init:
			pushad
			mov DWORD [fat32_res], 0
			mov BYTE [fat32_dirs_num], 0
			mov BYTE [fat32_dirs_num_saved], 0
			mov BYTE [fat32_fs_inited], 0
			mov DWORD [fat32_curr_sector_num], -1
			mov DWORD [fat32_free_clusters_cnt], FAT32_FSINFO_UNKNOWN
			mov DWORD [fat32_next_free_cluster_num], FAT32_FSINFO_UNKNOWN
			; read MBR (and partition-table from it)
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, 0
			xor ebp, ebp
			mov eax, FAT32_SECTOR_BUFF
			mov ebx, 1
			call hd_read
			cmp al, 0
			jz	.PType
			mov ebx, fat32_HDReadErrTxt
			call gstdio_draw_text
			jmp	.Back
.PType		mov esi, FAT32_SECTOR_BUFF
			add esi, FAT32_PARTITION_TABLE_OFFS
			add	esi, 4
			mov bl, [esi]
			mov [fat32_partition_type_code], bl
;			cmp bl, FAT32_TYPE_CODE1					; fails if checked
;			jz	.ReadLBA
;			cmp bl, FAT32_TYPE_CODE2					; fails if checked
;			jnz	.Back
.ReadLBA	add esi, 4
			mov ebx, [esi]
			mov [fat32_partition_lba_begin], ebx
			add esi, 4
			mov ebx, [esi]
			mov [fat32_partition_sectors_cnt], ebx
			; read VolumeID
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, [fat32_partition_lba_begin]
			xor ebp, ebp
			mov eax, FAT32_SECTOR_BUFF
			mov ebx, 1
			call hd_read
			cmp al, 0
			jz	.Copy
			mov ebx, fat32_HDReadErrTxt
			call gstdio_draw_text
			jmp	.Back
.Copy		mov esi, FAT32_SECTOR_BUFF
			add esi, FAT32_BYTES_PER_SECTOR_OFFS
			mov edi, fat32_bytes_per_sector
			mov ecx, 6
			rep	movsb
			mov esi, FAT32_SECTOR_BUFF
			add esi, FAT32_SECTORS_PER_FAT_OFFS
			mov ebx, [esi]
			mov [fat32_sectors_per_fat], ebx
			sub esi, FAT32_SECTORS_PER_FAT_OFFS
			add esi, FAT32_ROOT_DIR_CLUSTER_OFFS
			mov ebx, [esi]
			mov [fat32_root_dir_cluster], ebx
			; fill root-data to pwd-buffs
			mov [fat32_dir_clusters], ebx
			mov BYTE [FAT32_PATH_BUFF], FAT32_ROOTDIR_CHAR
			mov BYTE [FAT32_PATH_BUFF+1], 0
				; end of filling root-data
			sub esi, FAT32_ROOT_DIR_CLUSTER_OFFS
			add esi, FAT32_FSINFO_SECTOR_OFFS
			xor ebx, ebx
			mov bx, [esi]
			mov [fat32_fsinfo_sector], ebx
			sub esi, FAT32_FSINFO_SECTOR_OFFS
			add esi, FAT32_COPY_BOOTSECTOR_CLUSTER_OFFS
			xor ebx, ebx
			mov bx, [esi]
			mov [fat32_copy_boot_sector], ebx

			; calculate number of clusters per word (i.e. 16bits); 65535/sectors_per_cluster
			xor edx, edx
			mov eax, 0xFFFF
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			div ebx
			mov [fat32_max_clusters_num_per_word], ax

			; check the validity of FAT32
			cmp WORD [fat32_bytes_per_sector], FAT32_BYTES_SECTOR
			jz	.ChkFATs
			mov ebx, fat32_SectorByteCntErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkFATs	cmp BYTE [fat32_fats_num], 1
			jz	.ChkSig
			mov ebx, fat32_FATCntErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkSig		mov esi, FAT32_SECTOR_BUFF
			add esi, FAT32_SIGNATURE_OFFS
			cmp WORD [esi], 0xAA55
			jz	.Calc
			mov ebx, fat32_SigErrTxt
			call gstdio_draw_text
			jmp	.Back
			; calc fat_begin_lba and cluster_begin_lba
.Calc		mov ecx, [fat32_partition_lba_begin]
			xor ebx, ebx
			mov bx, [fat32_reserved_sectors_num]
			add ecx, ebx
			mov [fat32_fat_begin_lba], ecx
			xor eax, eax
			mov al, [fat32_fats_num]
			mov ebx, [fat32_sectors_per_fat]
			mul ebx
			add ecx, eax
			mov [fat32_cluster_begin_lba], ecx
				; root_dir_lba
			mov ebx, [fat32_root_dir_cluster]
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
;call gstdio_new_line
;push eax
;mov eax, ebx
;call gstdio_draw_dec
;call gstdio_new_line
;pop eax
;call gstdio_draw_dec
;call gstdio_new_line
;call gutil_press_a_key
			mov [fat32_root_dir_lba], eax
				; dir_entries_per_cluster_num
			xor eax, eax
			mov al, [fat32_sectors_per_cluster]
			shl	eax, 4										; *16, (512/32=16 (number of dir-entries per sector))
			mov [fat32_dir_entries_per_cluster_num], eax

			call fat32_read_fsinfo
			cmp DWORD [fat32_res], 1
			jz	.Ok
			mov ebx, fat32_ReadFSInfoErrTxt
			call gstdio_draw_text
			jmp	.Back

.Ok			mov BYTE [fat32_fs_inited], 1
			mov DWORD [fat32_res], 1
.Back		popad
			ret


; IN: -
; OUT: fat32_res (0 faliure)
fat32_fsinfo:
			pushad
			mov DWORD [fat32_res], 0
			cmp BYTE [fat32_fs_inited], 1
			jz	.Print
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
.Print		call gstdio_new_line
			mov ebx, fat32_FSInfoTxt
			call gstdio_draw_text
			mov ebx, fat32_TotalSectorsTxt
			call gstdio_draw_text
			mov edx, [ata_maxlba]	
			call gstdio_draw_hex
			call gstdio_new_line
			mov ebx, fat32_FATBeginLBATxt
			call gstdio_draw_text
			mov edx, [fat32_fat_begin_lba]
			call gstdio_draw_hex
			call gstdio_new_line
			mov ebx, fat32_SectorsPerFATTxt
			call gstdio_draw_text
			mov edx, [fat32_sectors_per_fat]
			call gstdio_draw_hex
			call gstdio_new_line
			mov ebx, fat32_ClustersBeginLBATxt
			call gstdio_draw_text
			mov edx, [fat32_cluster_begin_lba]
			call gstdio_draw_hex
			call gstdio_new_line
			mov ebx, fat32_SectorsPerClusterTxt
			call gstdio_draw_text
			;xor edx, edx
			mov dh, [fat32_sectors_per_cluster]
			call gstdio_draw_hex8
			call gstdio_new_line
			mov ebx, fat32_FreeClustersCountTxt
			call gstdio_draw_text
			mov edx, [fat32_free_clusters_cnt]
			call gstdio_draw_hex
			call gstdio_new_line
			mov ebx, fat32_FirstFreeClusterNumTxt
			call gstdio_draw_text
			mov edx, [fat32_next_free_cluster_num]
			call gstdio_draw_hex
			call gstdio_new_line
			mov DWORD [fat32_res], 1
.Back		popad
			ret


; Updates the FSInfo-structure on disk (FreeClusterCount)
; It doesn't update the NextFreeClusterNum because NextFreeClusterNum is 
; the most recently allocated clusternum, but we don't know that now.
; NextFreeClusterNum is the clusternum the search for free cluster starts from.
; If we wrote to the filesystem and forgot to call USBFSREM right before removing the disk, 
; the FSInfo-structure on disk didn't get updated.
; Call USBFSINFOUPD to fix it.
; Note: this may take some time depending on the size of the drive, 
; because it scans the FAT-table
; IN: -
; OUT: fat32_res (0 faliure)
fat32_fsinfoupd:
			pushad
			mov DWORD [fat32_res], 0
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
			; calculate number of free clusters
.Inited		mov DWORD [fat32_free_clusters_cnt], 0
			xor ebx, ebx
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
.NextSect	call fat32_read_fat							; IN: ECX(lbaLO)
			cmp BYTE [fat32_hd_res], 0
			jz	.ClearPIT
			mov ebx, fat32_ReadFATErrTxt
			call gstdio_draw_text
			jmp	.Back
.ClearPIT	mov DWORD [pit_task_ticks], 0					; clear pit-ticks 
			; find first 0 in buffer
			mov esi, FAT32_SECTOR_BUFF
			; if first sector of FAT, then skip first two cluster-numbers
			cmp ebx, 0
			jnz	.Read
			add esi, 8	
.Read		cmp DWORD [esi], 0
			je	.Inc
			cmp BYTE [esi], FAT32_DELETED_ENTRY	
			jne	.Next
.Inc		inc DWORD [fat32_free_clusters_cnt]
.Next		add esi, 4
			cmp esi, FAT32_SECTOR_BUFF+FAT32_BYTES_SECTOR
			jne	.Read
			inc ebx
			cmp ebx, [fat32_sectors_per_fat]
			jc	.NextSect
			mov DWORD [fat32_next_free_cluster_num], FAT32_FSINFO_UNKNOWN	; OR LAST NON 0 OR 0xE5 ENTRY !?
			call fat32_write_fsinfo
.Back		popad
			ret


; IN: EAX(1 if long list)
; OUT: fat32_res (0 faliure)
fat32_ls:
			pushad
			mov DWORD [fat32_res], 0
			mov DWORD [fat32_curr_sector_num], -1
			; check if FS initialized
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
.Inited		mov BYTE [fat32_long_list], al
			call gstdio_new_line
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
			call fat32_read_curr_dir
.ChkRes		cmp BYTE [fat32_hd_res], 0
			jz	.Start
			mov ebx, fat32_ReadClusErrTxt
			call gstdio_draw_text
			jmp	.Back
.Start		mov esi, FAT32_CLUSTER_BUFF
.GetEntry	cmp BYTE [esi], 0								; end of dir-entries?
			jz	.Ok
			cmp BYTE [esi], FAT32_DELETED_ENTRY
			jz	.Inc
			; read and print entry
	;IN: ESI(chars), ECX(number of chars to print), colors memory locations
			xor ecx, ecx
			mov cl, [esi]
			inc esi
			call gstdio_draw_chars
			dec esi
			push ebx
			mov ebx, ' '
			call gstdio_draw_char
			pop ebx
			cmp BYTE [fat32_long_list], 1
			jnz	.Inc
			; print dir, date, length
	; IN: ESI(ptr to entry), EBP(date-offset in record)
			push ebx
			mov al, [esi+FAT32_DE_ATTRIB]
			and al, FAT32_ATTR_DIRECTORY
			jz	.File
			mov ebx, fat32_folderTxt
			call gstdio_draw_text
.File		mov ebp, FAT32_DE_DATE_CR
			call fat32_print_date
			mov ebx, ' '
			call gstdio_draw_char
			mov ebp, FAT32_DE_DATE_LAST
			call fat32_print_date
			mov ebx, ' '
			call gstdio_draw_char
			mov ebp, FAT32_DE_DATE_WR
			call fat32_print_date
			mov ebx, ' '
			call gstdio_draw_char
			pop ebx
			mov eax, [esi+FAT32_DE_SIZE]
			call gstdio_draw_dec
			call gstdio_new_line
.Inc		add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_CLUSTER_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]
			jc	.GetEntry
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			call fat32_get_next_cluster_num
			cmp DWORD [fat32_res], 1
			jz	.ChkEOM
			mov ebx, fat32_GetNextClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkEOM		cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			je	.Ok
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
	; IN: ECX(LBALo)
	; OUT: FAT32_CLUSTER_BUF (data)
			mov ecx, eax
			call fat32_read_clus
			jmp .ChkRes
.Ok			mov DWORD [fat32_res], 1
.Back		call gstdio_new_line
			popad
			ret


; IN: EBX(addrofname, first byte is length)
; OUT: fat32_res (0 faliure)
fat32_cd:
			pushad
			mov DWORD [fat32_res], 0
			mov DWORD [fat32_curr_sector_num], -1
			; check if FS initialized
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
.Inited		cmp BYTE [ebx], FAT32_MAX_NAME_LEN-1
			jna .ChkDep
			mov ebx, fat32_NameTooLongErrTxt
			call gstdio_draw_text
			jmp .Back
.ChkDep		cmp BYTE [fat32_dirs_num], FAT32_MAX_DIR_DEPTH_NUM
			jge	.Back
			; length is 1 ?
			cmp BYTE [ebx], 1
			jnz .ChkBack
			; is name '.' ?
			cmp BYTE [ebx+1], '.'
			jz	.Back
			; is name root-dir?
			cmp BYTE [ebx+1], FAT32_ROOTDIR_CHAR
			jnz .ChkBack
			mov BYTE [fat32_dirs_num], 0
			jmp .Ok
			; is name '..' ?
.ChkBack	cmp BYTE [ebx], 2
			jnz .Find
			cmp WORD [ebx+1], ".."
			jnz	.Find
			cmp BYTE [fat32_dirs_num], 0
			jz	.Back
			dec BYTE [fat32_dirs_num]
			jmp .Ok
.Find		mov [fat32_name_addr], ebx
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
			call fat32_read_curr_dir
.ChkRes		cmp BYTE [fat32_hd_res], 0
			jz	.Get
			mov ebx, fat32_ReadCurrDirErrTxt
			call gstdio_draw_text
			jmp	.Back
.Get		mov esi, FAT32_CLUSTER_BUFF
.GetEntry	cmp BYTE [esi], 0								; end of dir-entries?
			jz	.Back
			cmp BYTE [esi], FAT32_DELETED_ENTRY
			jz	.Inc
		; read entry
			mov al, [esi+FAT32_DE_ATTRIB]
			and al, FAT32_ATTR_DIRECTORY
			jz	.Inc
			; check length
			mov edi, [fat32_name_addr]
			xor eax, eax
			mov al, [esi+FAT32_DE_NAME]
			cmp BYTE [edi], al
			jnz .Inc
			; check chars
			mov edx, esi
.NextChar	inc edx
			inc edi
			push eax
			mov al, [edx]
			cmp BYTE [edi], al
			pop eax
			jnz	.Inc
			dec al
			cmp al, 0
			jnz	.NextChar
		; Found	; copy name
			push esi
			mov esi, [fat32_name_addr]
			xor ecx, ecx
			mov cl, [esi]
			inc esi								; skip length-byte
			mov edi, FAT32_PATH_BUFF
			mov eax, FAT32_MAX_NAME_LEN
			xor ebx, ebx
			mov bl, [fat32_dirs_num]
			inc ebx
			mul ebx
			add edi, eax
			rep movsb
			mov BYTE [edi], 0
			pop esi
				; end of copying
			xor eax, eax
			mov eax, [esi+FAT32_DE_CLUS_NUM]
			inc BYTE [fat32_dirs_num]
			xor ebx, ebx
			mov bl, BYTE [fat32_dirs_num]
;			dec	ebx
			shl	ebx, 2
			add ebx, fat32_dir_clusters
			mov [ebx], eax
			jmp .Ok
.Inc		add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_CLUSTER_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]
			jc	.GetEntry
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			call fat32_get_next_cluster_num
			cmp DWORD [fat32_res], 1
			jnz	.ChkEOM
			mov ebx, fat32_GetNextClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkEOM		cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			je	.Ok
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
	; IN: ECX(LBALo)
	; OUT: FAT32_CLUSTER_BUF (data)
			mov ecx, eax
			call fat32_read_clus
			jmp .ChkRes
.Ok			mov DWORD [fat32_res], 1
.Back		popad
			ret


; IN: -
; OUT: fat32_res (0 faliure)
fat32_pwd:
			pushad
			mov DWORD [fat32_res], 0
			; check if FS initialized
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
.Inited		call gstdio_new_line
			xor ecx, ecx
.Next		mov eax, ecx
			mov ebx, FAT32_MAX_NAME_LEN
			mul ebx
			mov ebx, FAT32_PATH_BUFF
			add ebx, eax
			call gstdio_draw_text
			cmp ecx, 0
			jz	.Inc								; skip separator-char if root-dir
			xor ebx, ebx
			mov bl, FAT32_PATH_SEPARATOR_CHAR
			call gstdio_draw_char
.Inc		inc ecx
			cmp cl, [fat32_dirs_num]
			jna	.Next								; jump if unsigned not above
.Ok			mov DWORD [fat32_res], 1
			call gstdio_new_line
.Back		popad
			ret


; IN: EAX(memaddr), EBX(addrofname, first byte is length)
; OUT: fat32_res (0 faliure), ECX(size of file in bytes)
fat32_read:
			pushad
			mov DWORD [fat32_res], 0
			mov DWORD [fat32_curr_sector_num], -1
			; check if FS initialized
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
;.Inited		cmp BYTE [fat32_dirs_num], FAT32_MAX_DIR_DEPTH_NUM
;			jge	.Back
.Inited		cmp BYTE [ebx], FAT32_MAX_NAME_LEN-1
			jna .Store
			mov ebx, fat32_NameTooLongErrTxt
			call gstdio_draw_text
			jmp .Back
.Store		mov [fat32_memaddr], eax
			mov [fat32_name_addr], ebx
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
			call fat32_read_curr_dir
.ChkRes		cmp BYTE [fat32_hd_res], 0
			jz	.Get
;		mov ebx, fat32_DbgFSReadTxt
;		call gstdio_draw_text
			mov ebx, fat32_ReadCurrDirErrTxt
			call gstdio_draw_text
			jmp	.Back
.Get		mov esi, FAT32_CLUSTER_BUFF
.GetEntry	cmp BYTE [esi], 0								; end of dir-entries?
			jz	.Back
			cmp BYTE [esi], FAT32_DELETED_ENTRY
			jz	.Inc
			mov al, [esi+FAT32_DE_ATTRIB]
			and al, FAT32_ATTR_DIRECTORY
			jnz	.Inc
		; check entry
	; IN: ESI (addrname1), EDI(addrofname2)
	; OUT: EAX(0 if found)
			mov edi, [fat32_name_addr]
			call fat32_check_names
			cmp al, 0
			jnz	.Inc
		; Found
			mov ebx, [esi+FAT32_DE_CLUS_NUM]		; Note: EBX was the Dir-clusnum, so we overwrite it with the file's
			mov eax, [esi+FAT32_DE_SIZE]
			mov [fat32_filesize], eax

			;check if clusnum or length of file is zero
			cmp ebx, 0
			je	.Ok
			cmp eax, 0
			je	.Ok
			; read file from its cluster
			; read cluster, then from FAT the next ones
	; IN: EBX(clusternum to read)
	; OUT: ECX(number of consecutive clusters); EDX(the next clusternumber after the consecutive ones)
.NextClus	call fat32_get_consec_cluster_num
			cmp DWORD [fat32_res], 1
			jz	.ToLBA
			mov ebx, fat32_GetConsecClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: EBX(clusternum)
	; OUT: EAX
.ToLBA		mov [fat32_next_clusnum], edx
			call fat32_cluster2lba
			push ebx
			push eax
			mov eax, ecx
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			mul ebx
			mov edx, eax										; sectorcnt in EDX
;			mov [fat32_sectorcnt], edx
			pop eax
			push edx
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, eax
			xor ebp, ebp
			mov eax, [fat32_memaddr]
			mov ebx, edx
			call hd_read
			cmp al, 0
			pop edx
			pop ebx
			jz	.ChkEOM
			mov ebx, fat32_HDReadErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkEOM		mov ebx, [fat32_next_clusnum]
			cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			je	.Ok
			mov DWORD [pit_task_ticks], 0						; clear pit-counter
			; increment memaddr
			xor eax, eax
			mov	ax, [fat32_bytes_per_sector]
			push ebx
			mov ebx, edx ;[fat32_sectorcnt]						; EDX(sectorcnt)
			mul ebx
			pop ebx
			add [fat32_memaddr], eax
			; end of increment
			jmp .NextClus
.Inc		add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_CLUSTER_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]
			jc	.GetEntry
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			call fat32_get_next_cluster_num	
			cmp DWORD [fat32_res], 1
			jnz	.Back
			cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			je	.Ok
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
			mov ecx, eax
			call fat32_read_clus
			jmp .ChkRes
.Ok			mov DWORD [fat32_res], 1
.Back		popad
			mov ecx, [fat32_filesize]
			ret


; IN: EAX(memaddr), ECX(size in bytes), EBX(addrofname, first byte is length)
; OUT: fat32_res (0 faliure)
fat32_write:
			pushad
			mov DWORD [fat32_res], 0
			mov DWORD [fat32_curr_sector_num], -1
			; check if FS initialized
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
;.Inited		cmp BYTE [fat32_dirs_num], FAT32_MAX_DIR_DEPTH_NUM
;			jge	.Back
.Inited		cmp BYTE [ebx], FAT32_MAX_NAME_LEN-1
			jna .Store
			mov ebx, fat32_NameTooLongErrTxt
			call gstdio_draw_text
			jmp .Back
.Store		mov [fat32_memaddr], eax
			mov [fat32_name_addr], ebx
			mov [fat32_file_size], ecx
			; calculate how many clusters we need
			xor edx, edx
			mov eax, [fat32_file_size]
			cmp eax, 0
			je	.NoRem
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			shl ebx, 9										; *512 to get bytes
			div ebx
			cmp edx, 0
			je	.NoRem
			inc eax
.NoRem		mov [fat32_clusters_cnt], eax
			cmp DWORD [fat32_free_clusters_cnt], FAT32_FSINFO_UNKNOWN
			jne	.ChkCnt
			mov ebx, fat32_FreeClusCntUnkTxt
			call gstdio_draw_text
			jmp .Back
.ChkCnt		cmp eax, [fat32_free_clusters_cnt]
			jna	.Read
			mov ebx, fat32_NoFreeClusErrTxt
			call gstdio_draw_text
			jmp .Back
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
.Read		call fat32_read_curr_dir	
			cmp BYTE [fat32_hd_res], 0
			jz	.ChkName
			mov ebx, fat32_ReadCurrDirErrTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: fat32_name_addr, FAT32_CLUSTER_BUFF
	; OUT: fat32_res(1 if available, so the name doesn't exist in the current dir)
.ChkName	call fat32_is_name_available
			cmp DWORD [fat32_res], 1
			jz	.Avail
			mov ebx, fat32_NameAlreadyExistsErrTxt
			call gstdio_draw_text
			jmp	.Back
.Avail		mov BYTE [fat32_add_dir_end], 0		; !!!???
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
			call fat32_read_curr_dir
.ChkRes		cmp BYTE [fat32_hd_res], 0
			jz	.Set
			mov ebx, fat32_ReadCurrDirErrTxt
			call gstdio_draw_text
			jmp	.Back
.Set		mov esi, FAT32_CLUSTER_BUFF
.FindFree	cmp BYTE [esi], FAT32_DELETED_ENTRY
			je	.Fnd
			cmp BYTE [esi], 0								; end of dir-entries?
			jnz	.Inc
			mov BYTE [fat32_add_dir_end], 1					; zero needs to be written in the next dir-entry
	; IN: ESI(addr of entry), EBX(clusternum), ECX(filesizeinbytes), fat32_name_addr(with size at the front), fat32_attr_byte, fat32_add_dir_end
	; OUT: EBX(cluster_num (adds first cluster of file (if filesize is not zero), or directory), fat32_res
.Fnd		mov ecx, [fat32_file_size]
			mov BYTE [fat32_attr_byte], 0
			call fat32_create_dir_entry	
			cmp DWORD [fat32_res], 1
			jz	.ChkClus
			mov ebx, fat32_CreateDirEntryErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkClus	cmp DWORD [fat32_file_size], 0					; if file was created with size of zero, then nothing to write
			je	.Ok
			xor ecx, ecx
			; write file to cluster
	; IN: EBX(clusternum)
	; OUT: EAX
.Write		call fat32_cluster2lba
			; check if last cluster
			mov edx, [fat32_clusters_cnt]
			sub edx, ecx
				; end of checking last cluster
			push ecx
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov ecx, eax
			mov eax, [fat32_memaddr]
			push ebx
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			cmp edx, 1								; last cluster?
			jne	.Wr
			; check if less number of sectors is needed than sectorspercluster
			push ebp
			mov edx, [fat32_file_size]				; the rest of the size to write (bytespercluster gets subtracted later)
			mov ebp, edx
			shr	edx, 9								; how many sectors is the current file-size?
			and ebp, 0x1FF							; bytes less than bytespersectors
			jz	.SkipRem
			inc edx
.SkipRem	pop ebp
			cmp edx, ebx
			jnc	.Wr									; jump if unsigned greater or equal
			cmp edx, 0								; this shouldn't happen, because we have the last cluster to write, so at least 1 sector
			jnz	.SetSec
			inc edx									; if remaining filesize<512, then 1 instead of 0 sector
.SetSec		mov ebx, edx
.Wr			call hd_write
			cmp al, 0
			pop ebx
			pop ecx
			jz	.UpdFree
			mov ebx, fat32_HDWriteErrTxt
			call gstdio_draw_text
			jmp	.Back
.UpdFree	mov [fat32_next_free_cluster_num], ebx		; update NextFreeClusNum
			; increment address, then find new cluster, then repeat
			xor eax, eax
			mov al, [fat32_sectors_per_cluster]
			shl	eax, 9								; *512
			add [fat32_memaddr], eax
			sub [fat32_file_size], eax				; !?
			inc ecx
			cmp ecx, [fat32_clusters_cnt]
			je	.Ok
	; IN: EBX(clusternum; eg. 2 for RootDir)
	; OUT: EBX(new clusternum)
			; add new cluster
			call fat32_add_new_cluster	
			cmp DWORD [fat32_res], 1
			jz	.Write
			mov ebx, fat32_AddNewClusterErrTxt
			call gstdio_draw_text
			jmp	.Back
.Inc		mov DWORD [pit_task_ticks], 0						; clear pit-counter
			add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_CLUSTER_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]
			jc	.FindFree									; jump if unsigned smaller
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			call fat32_get_next_cluster_num
			cmp DWORD [fat32_res], 1
			jz	.ChkEOM
			mov ebx, fat32_GetNextClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkEOM		cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			jc	.Read2		; or jne
			mov ebx, fat32_EndOfClusMarkerFndTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: EBX(clusternum)
	; OUT: EAX
.Read2		call fat32_cluster2lba
	; IN: ECX(LBALo)
	; OUT: FAT32_CLUSTER_BUF (data)
			mov ecx, eax
			call fat32_read_clus
			jmp .ChkRes
.Ok			mov DWORD [fat32_res], 1
			mov eax, [fat32_clusters_cnt]
			sub [fat32_free_clusters_cnt], eax
.Back		popad
			ret


; IN: EBX(addrofname, first byte is length)
; OUT: fat32_res (0 faliure)
fat32_mkdir:
			pushad
			mov DWORD [fat32_res], 0
			mov DWORD [fat32_curr_sector_num], -1
			; check if FS initialized
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
;.Inited		cmp BYTE [fat32_dirs_num], FAT32_MAX_DIR_DEPTH_NUM
;			jge	.Back
.Inited		cmp BYTE [ebx], FAT32_MAX_NAME_LEN-1
			jna .Store
			mov ebx, fat32_NameTooLongErrTxt
			call gstdio_draw_text
			jmp .Back
.Store		mov [fat32_name_addr], ebx
			cmp DWORD [fat32_free_clusters_cnt], FAT32_FSINFO_UNKNOWN
			jne	.ChkCnt
			mov ebx, fat32_FreeClusCntUnkTxt
			call gstdio_draw_text
			jmp .Back
.ChkCnt		cmp DWORD [fat32_free_clusters_cnt], 1
			jnc	.Rd									; jump if unsigned greater or equal
			mov ebx, fat32_NoFreeClusErrTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
.Rd			call fat32_read_curr_dir
			cmp BYTE [fat32_hd_res], 0
			jz	.ChkName
			mov ebx, fat32_ReadCurrDirErrTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: fat32_name_addr, FAT32_CLUSTER_BUFF
	; OUT: fat32_res(1 if available, so the name doesn't exist in the current dir)
.ChkName	call fat32_is_name_available
			cmp DWORD [fat32_res], 1
			jz	.Avail
			mov ebx, fat32_NameNotAvailErrTxt
			call gstdio_draw_text
			jmp	.Back
.Avail		mov BYTE [fat32_add_dir_end], 0		; !!!???
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum, FAT32_CLUSTER_BUFF, fat32_hd_res
			call fat32_read_curr_dir
.ChkRes		cmp BYTE [fat32_hd_res], 0
			jz	.Set
			mov ebx, fat32_ReadCurrDirErrTxt
			call gstdio_draw_text
			jmp	.Back
.Set		mov esi, FAT32_CLUSTER_BUFF
.FindFree	cmp BYTE [esi], FAT32_DELETED_ENTRY
			je	.Fnd
			cmp BYTE [esi], 0								; end of dir-entries?
			jnz	.Inc
			mov BYTE [fat32_add_dir_end], 1					; zero needs to be written in the next dir-entry
	; IN: ESI(addr of entry), EBX(clusternum), ECX(filesizeinbytes), fat32_name_addr(with size at the front), fat32_attr_byte, fat32_add_dir_end
	; OUT: EBX(cluster_num (adds first cluster of file (if filesize is not zero), or directory), fat32_res
.Fnd		mov ecx, 1											; just to create the one cluster
			mov BYTE [fat32_attr_byte], FAT32_ATTR_DIRECTORY
			call fat32_create_dir_entry	
			cmp DWORD [fat32_res], 1
			jz	.Upd
			mov ebx, fat32_CreateDirEntryErrTxt
			call gstdio_draw_text
			jmp	.Back
.Upd		mov [fat32_next_free_cluster_num], ebx				; update NextFreeClusNum
			; if directory, write a zero to the first entry of the new cluster
			mov BYTE [FAT32_CLUSTER_BUFF], 0
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov ecx, eax
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			mov eax, FAT32_CLUSTER_BUFF
			call hd_write
			cmp al, 0
			jz	.Ok
			mov ebx, fat32_HDWriteErrTxt
			call gstdio_draw_text
			jmp	.Back
.Inc		mov DWORD [pit_task_ticks], 0						; clear pit-counter
			add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_CLUSTER_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]
			jc	.FindFree
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			call fat32_get_next_cluster_num
			cmp DWORD [fat32_res], 1
			jz	.ChkEOM
			mov ebx, fat32_GetNextClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkEOM		cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			jc	.Rd2		; or jne						; jump if unsigned smaller
			mov ebx, fat32_EndOfClusMarkerFndTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: EBX(clusternum)
	; OUT: EAX
.Rd2		call fat32_cluster2lba
	; IN: ECX(LBALo)
	; OUT: FAT32_CLUSTER_BUF (data)
			mov ecx, eax
			call fat32_read_clus
			jmp .ChkRes
.Ok			mov DWORD [fat32_res], 1
			mov eax, [fat32_clusters_cnt]
			sub [fat32_free_clusters_cnt], eax
.Back		popad
			ret


; IN: EBX(addrofname, first byte is length)
; OUT: fat32_res (0 faliure)
; deletes folder or file
; In case of a folder checks if it is empty
fat32_del:
			pushad
			mov DWORD [fat32_res], 0
			mov DWORD [fat32_curr_sector_num], -1
			; check if FS initialized
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
;.Inited		cmp BYTE [fat32_dirs_num], FAT32_MAX_DIR_DEPTH_NUM
;			jge	.Back
.Inited		cmp BYTE [ebx], FAT32_MAX_NAME_LEN-1
			jna .Store
			mov ebx, fat32_NameTooLongErrTxt
			call gstdio_draw_text
			jmp .Back
.Store		mov [fat32_name_addr], ebx
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
			call fat32_read_curr_dir
.ChkRes		cmp BYTE [fat32_hd_res], 0
			jz	.Set
			mov ebx, fat32_ReadCurrDirErrTxt
			call gstdio_draw_text
			jmp	.Back
.Set		mov esi, FAT32_CLUSTER_BUFF
.GetEntry	cmp BYTE [esi], 0								; end of dir-entries?
			jz	.Back
			cmp BYTE [esi], FAT32_DELETED_ENTRY
			jz	.Inc
		; check entry
	; IN: ESI (addrname1), EDI(addrofname2)
	; OUT: EAX(0 if found)
			mov edi, [fat32_name_addr]
			call fat32_check_names
			cmp al, 0
			jnz	.Inc
		; Found
			; check if directory, and if it is a directory then it is empty
			mov al, [esi+FAT32_DE_ATTRIB]
			and al, FAT32_ATTR_DIRECTORY
			jz	.Del
			push ebx
			mov ebx, [esi+FAT32_DE_CLUS_NUM]
			call fat32_check_folder
			pop ebx
			cmp BYTE [fat32_is_folder_empty], 1
			je	.Del
			mov ebx, fat32_FolderNotEmptyErrTxt
			call gstdio_draw_text
			jmp .Back
.Del		mov BYTE [esi+FAT32_DE_NAME], FAT32_DELETED_ENTRY
			mov eax, [esi+FAT32_DE_CLUS_NUM]
			push eax
		; write cluster back to disk
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov ecx, eax
			push ebx
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			mov eax, FAT32_CLUSTER_BUFF
			call hd_write
			pop ebx
			cmp al, 0
			pop eax
			jz	.ChkFree
			mov ebx, fat32_HDWriteErrTxt
			call gstdio_draw_text
			jmp	.Back
	; what about checkfree before writing the cluster back to disk!?
.ChkFree	cmp [fat32_next_free_cluster_num], ebx
			jna	.NextClus								; jump if unsigned smaller or equal
			mov [fat32_next_free_cluster_num], ebx		; update NextFreeClusNum
	; read 1 sector from FAT (which contains the current cluster), save next clusternum, write zero to FAT, do again with nextclus
		; !? check if nextclus is in this FAT-Sector, and zero that too before writing it back to disk!?
.NextClus	mov ebx, eax
		; EBX(clusternum)
			mov ebp, ebx
			and ebp, FAT32_OFFSET_WITHIN_SECTOR_MASK
			shl ebp, 2										; the offset is in DWORDS
			shr ebx, 7										; EBX: sectornumber in FAT
			mov ecx, ebx									; save current FAT-sector num
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
			call fat32_read_fat
			cmp BYTE [fat32_hd_res], 0
			jz	.Clear
			mov ebx, fat32_ReadFATErrTxt
			call gstdio_draw_text
			jmp	.Back
.Clear		mov esi, FAT32_SECTOR_BUFF
			add esi, ebp
			mov eax, [esi]									; save next cluster-number	
			mov DWORD [esi], 0
			cmp eax, FAT32_END_OF_CLUSTER_MARKER
			je	.Write
		; is next cluster-numer in the current FAT-sector? (if no write FAT-sector to disk)
			mov ebx, eax
			mov ebp, ebx
			and ebp, FAT32_OFFSET_WITHIN_SECTOR_MASK
			shl ebp, 2										; the offset is in DWORDS
			shr ebx, 7										; EBX: sectornumber in FAT
			cmp ebx, ecx
			je	.Clear
		; Write back to disk
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
.Write		call fat32_write_fat
			cmp BYTE [fat32_hd_res], 0
			jz	.Ok
			mov ebx, fat32_WriteFATErrTxt
			call gstdio_draw_text
			jmp	.Back
			cmp eax, FAT32_END_OF_CLUSTER_MARKER
			jne	.NextClus
		; if (clusternum < fat32_next_free_cluster_num) then update fat32_next_free_cluster_num
			cmp eax, [fat32_next_free_cluster_num]
			jnc	.Ok										; jump if unsigned greater or equal
			mov [fat32_next_free_cluster_num], eax		; update NextFreeClusNum
			jmp .Ok
.Inc		add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_CLUSTER_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]
			jc	.GetEntry
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			call fat32_get_next_cluster_num	
			cmp DWORD [fat32_res], 1
			jz	.ChkEOM
			mov ebx, fat32_GetNextClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkEOM		cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			jc	.Rd			; or jne						; jump if unsigned smaller
			mov ebx, fat32_EndOfClusMarkerFndTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: EBX(clusternum)
	; OUT: EAX
.Rd			call fat32_cluster2lba
	; IN: ECX(LBALo)
	; OUT: FAT32_CLUSTER_BUF (data)
			mov ecx, eax
			call fat32_read_clus
			jmp .ChkRes
.Ok			mov DWORD [fat32_res], 1
.Back		popad
			ret


; IN: EBX(addrofname, first byte is length), EDX(addrofNEWName, first byte is length)
; OUT: fat32_res (0 faliure)
; renames a folder or file
fat32_ren:
			pushad
			mov DWORD [fat32_res], 0
			mov DWORD [fat32_curr_sector_num], -1
			; check if FS initialized
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
;.Inited		cmp BYTE [fat32_dirs_num], FAT32_MAX_DIR_DEPTH_NUM
;			jge	.Back
.Inited		cmp BYTE [ebx], FAT32_MAX_NAME_LEN-1
			ja	.TooLong
			cmp BYTE [edx], FAT32_MAX_NAME_LEN-1
			jna .Store
.TooLong	mov ebx, fat32_NameTooLongErrTxt
			call gstdio_draw_text
			jmp .Back
.Store		mov [fat32_name_addr], ebx
			mov [fat32_new_name_addr], edx
	; IN: fat32_dirs_num
	; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
			call fat32_read_curr_dir
.ChkRes		cmp BYTE [fat32_hd_res], 0
			jz	.Set
			mov ebx, fat32_ReadCurrDirErrTxt
			call gstdio_draw_text
			jmp	.Back
.Set		mov esi, FAT32_CLUSTER_BUFF
.GetEntry	cmp BYTE [esi], 0								; end of dir-entries?
			jz	.Back
			cmp BYTE [esi], FAT32_DELETED_ENTRY
			jz	.Inc
		; check entry
	; IN: ESI (addrname1), EDI(addrofname2)
	; OUT: EAX(0 if found)
			mov edi, [fat32_name_addr]
			call fat32_check_names
			cmp al, 0
			jnz	.Inc
		; Found
			; copy name
			mov eax, esi
			mov esi, [fat32_new_name_addr]
			xor ecx, ecx
			mov cl, [esi]
			inc ecx										; include length-byte
			mov edi, eax
			rep movsb
			; write cluster back to disk
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
			push ecx
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov ecx, eax
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			mov eax, FAT32_CLUSTER_BUFF
			call hd_write
			cmp al, 0
			pop ecx
			jz	.Ok
			mov ebx, fat32_HDWriteErrTxt
			call gstdio_draw_text
			jmp	.Back
.Inc		add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_CLUSTER_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]
			jc	.GetEntry
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			call fat32_get_next_cluster_num	
			cmp DWORD [fat32_res], 1
			jz	.ChkEOM
			mov ebx, fat32_GetNextClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkEOM		cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			jc	.Rd			; or jne						; jump if unsigned smaller
			mov ebx, fat32_EndOfClusMarkerFndTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: EBX(clusternum)
	; OUT: EAX
.Rd			call fat32_cluster2lba
			mov ecx, eax
	; IN: ECX(LBALo)
	; OUT: FAT32_CLUSTER_BUF (data)
			call fat32_read_clus
			jmp .ChkRes
.Ok			mov DWORD [fat32_res], 1
.Back		popad
			ret


; Writes FSInfo sector to disk
;	Should be called before turning of the computer, if we wrote to the filesystem
; IN: -
; OUT: fat32_res (0 faliure)
; Should be done automatically at shutdown!
fat32_wr_fsinfo:
			pushad
			mov DWORD [fat32_res], 0
			cmp BYTE [fat32_fs_inited], 1
			jz	.Inited
			mov ebx, fat32_FSNotInitedErrTxt
			call gstdio_draw_text
			jmp	.Back
.Inited		call fat32_write_fsinfo
			cmp DWORD [fat32_res], 1
;			jz	.Rem
			jz	.Back
			mov ebx, fat32_WriteFSInfoErrTxt
			call gstdio_draw_text
			jmp	.Back
;.Rem		mov BYTE [fat32_fs_inited], 0
.Back		popad
			ret


;Format:
; - Sets sectorspercluster according to ata_capacity
; - Gets maxLBA (from ata_maxlba) [disktotalsectors]
; - Fills variables (partitionlbabegin, rootdircluster, ...)
; - Updates MBR and VBR (The data of the binary hdfsboot.asm and hdfsmbr.asm is added to the code by conv.py (hdfsbootdata and hdfsmbrdata))
; - Writes MBR and VBR to disk
; - Writes FSInfo-sector to disk
; - Formats FAT (writing zeroed out sectors)
; - Creates rootdir in FAT (writes EndOfClusterMarker to the second offset in FAT)
; - Creates root-cluster (zeros out the FAT32_CLUSTER_BUFF, then writes it to Cluster2)

;if 4GB-drive with 8K clusters:
;(4096*2^20)/(8*2^10)=2^19 clusters
;(2^19)*32bits=2^24bits --> 2097152bytes (2MB)
;4GB-2MB and calculate it again!? (2*2MB for 2*FATS)
; In sectors: maxlba/2*8= 2^19, etc

; <=8GB 8sectors(4Kcluster)
; <=16GB 16sectors(8Kcluster)
; <=32GB 32sectors(16Kcluster)
; >32GB 64sectors(32Kcluster)	; NOTE that BIOS INT 13h AH=42h: Extended Read Sectors From Drive dies with 64sectors!
								; that's why we set maximum sectorspercluster to 32. I found no memory-overwriting.
fat32_format:
			pushad
			call gstdio_new_line
			mov ebx, fat32_DataInDecTxt
			call gstdio_draw_text
			mov ebx, fat32_HDCapacityMBTxt
			call gstdio_draw_text
			mov edx, [ata_capacity]				; in MB
			mov eax, edx
			call gstdio_draw_dec
			call gstdio_new_line
			mov eax, 8	; sectorspercluster
;			cmp edx, 32*1024					; see above why we set sectorspercluster to max 32
;			ja	.Set64
			cmp edx, 16*1024
			ja	.Set32
			cmp edx, 8*1024
			ja	.Set16
			jmp .Store
;.Set64		mov eax, 64
;			jmp .Store
.Set32		mov eax, 32
			jmp .Store
.Set16		mov eax, 16
.Store		mov [fat32_sectors_per_cluster], al
			mov ebx, fat32_SectorsPerCluster2Txt
			call gstdio_draw_text
			xor eax, eax
			mov al, [fat32_sectors_per_cluster]
			call gstdio_draw_dec					; 8 (if 4Gb disk)
			call gstdio_new_line
	; note that we only use the lower 32-bits of the 48bitLBA (if ata_maxlba is not lba28). 32bitLBA can handle a maximum 2TB-drive
	;	So we will only use the lower 2T of a huge disk
			mov eax, [ata_maxlba]	
			mov [fat32_disktotalsectors], eax
			; calc sectorsperFAT
			xor edx, edx
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			div ebx
		; EAX(clustercnt)
			shl eax, 2					; *4 (to get DWORDS)
		; EAX(sizeofOneFATinbytes)
			mov ecx, eax
			shr ecx, 9					; /512 to get sectorcnt of FAT
		; maxlba-FATsizeInSectors, then do the calulation again
			mov eax, [fat32_disktotalsectors]
			sub eax, ecx
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			div ebx
		; EAX(clustercnt)
			shl eax, 2					; *4 (to get DWORDS)
		; EAX(sizeofOneFATinbytes)
			shr eax, 9					; to get #sectors
			mov [fat32_sectors_per_fat], eax
			mov ebx, fat32_SectorsPerFAT2Txt
			call gstdio_draw_text
			call gstdio_draw_dec
			call gstdio_new_line
			mov ebx, [hdfsbootdata+FAT32_BPBROOTDIRCLUSTER_OFFS]
			mov [fat32_root_dir_cluster], ebx
		; update VBR
			mov [hdfsbootdata+FAT32_BPBSECTORSPERFAT_OFFS], eax
			mov bl, [fat32_sectors_per_cluster]
			mov [hdfsbootdata+FAT32_BPBSECTORSPERCLUSTER_OFFS], bl
			mov eax, [fat32_disktotalsectors]
			mov [hdfsbootdata+FAT32_BPBLARGETOTALSECTORS_OFFS], eax
;	call gstdio_new_line
;	push esi
;	push ecx
;	mov esi, hdfsbootdata
;	mov ecx, 100
;	call gutil_mem_dump
;	pop ecx
;	pop esi
;	call gstdio_new_line

;	call gutil_press_a_key

		; update MBR
			mov [hdfsmbrdata+FAT32_MBR_PE1_SECTORS_OFFS], eax
			mov eax, [hdfsbootdata+FAT32_BPBHIDDENSECTORS_OFFS]
			mov [hdfsmbrdata+FAT32_MBR_PE1_LBA_OFFS], eax
			mov [fat32_partition_lba_begin], eax
;	call gstdio_new_line
;	push esi
;	push ecx
;	mov esi, hdfsmbrdata+0x1BE
;	mov ecx, 32
;	call gutil_mem_dump
;	pop ecx
;	pop esi
;	call gstdio_new_line

;	call gutil_press_a_key
			mov ebx, fat32_WritingMBRTxt
			call gstdio_draw_text
		; write MBR and VBR to disk
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			xor ecx, ecx
			mov ebx, 1
			mov eax, hdfsmbrdata
			call hd_write
			cmp al, 0
			jz	.WrVBR
			mov ebx, fat32_HDWriteMBRErrTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
.WrVBR		mov ebx, fat32_WritingVBRToSectorTxt
			call gstdio_draw_text
			xor ebp, ebp
			mov ecx, [hdfsbootdata+FAT32_BPBHIDDENSECTORS_OFFS]
			mov eax, ecx
			call gstdio_draw_dec
			call gstdio_new_line
			mov ebx, 1
			mov eax, hdfsbootdata
			call hd_write
			cmp al, 0
			jz	.FSInfo
			mov ebx, fat32_HDWriteVBRErrTxt
			call gstdio_draw_text
			jmp	.Back
		; clear sector-memory
.FSInfo		cld
			mov edi, FAT32_SECTOR_BUFF
			mov ecx, 512
			shr ecx, 2						; /4 to get DWORDS
			xor eax, eax
			rep stosd
		; fill data
			mov DWORD [FAT32_SECTOR_BUFF+FAT32_FSINFO_LEADSIG_OFFS], FAT32_FSINFO_LEADSIG
			mov DWORD [FAT32_SECTOR_BUFF+FAT32_FSINFO_STRUCSIG_OFFS], FAT32_FSINFO_STRUCSIG
			mov eax, [fat32_sectors_per_fat]
			shl eax, 7						; *128
			mov DWORD [FAT32_SECTOR_BUFF+FAT32_FSINFO_FREECLUSTERCNT_OFFS], eax
			mov DWORD [FAT32_SECTOR_BUFF+FAT32_FSINFO_NEXTFREECLUSTERNUM_OFFS], 0xFFFFFFFF	; or 0x00000002 !?
			mov DWORD [FAT32_SECTOR_BUFF+FAT32_FSINFO_TRAILSIG_OFFS], FAT32_FSINFO_TRAILSIG
			mov ebx, fat32_WritingFSInfoToSectorTxt
			call gstdio_draw_text
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov ecx, [hdfsbootdata+FAT32_BPBHIDDENSECTORS_OFFS]
			inc ecx
			mov eax, ecx
			call gstdio_draw_dec
			call gstdio_new_line
			mov ebx, 1
			mov eax, FAT32_SECTOR_BUFF
			call hd_write
			cmp al, 0
			jz	.FormatFAT
			mov ebx, fat32_HDWriteFSInfoErrTxt
			call gstdio_draw_text
			jmp	.Back
	; fill sector-buffer with zeros
.FormatFAT	cld
			mov edi, FAT32_SECTOR_BUFF
			mov ecx, 512
			shr ecx, 2						; /4 to get DWORDS
			xor eax, eax
			rep stosd
			mov ebx, fat32_ErasingFATTxt
			call gstdio_draw_text
	;fat_begin_lba = Partition_LBA_Begin + Number_of_Reserved_Sectors;
	;cluster_begin_lba = Partition_LBA_Begin + Number_of_Reserved_Sectors + (Number_of_FATs * Sectors_Per_FAT)
			mov eax, [fat32_partition_lba_begin]
			xor ebx, ebx
			mov bx, [hdfsbootdata+FAT32_BPBRESERVEDSECTORS_OFFS]
			mov [fat32_reserved_sectors_num], bx
			add eax, ebx
			mov [fat32_fat_begin_lba], eax
			mov ebx, [fat32_sectors_per_fat]
			add ebx, eax
			mov [fat32_cluster_begin_lba], ebx
			xor edx, edx
	; if we passed [fat32_sectors_per_fat] to hd_write, then it would increase memaddr accordingly !?
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
.Next		push edx
			xor ebp, ebp
			mov ecx, [fat32_fat_begin_lba]
			add ecx, edx
			mov ebx, 1
			mov eax, FAT32_SECTOR_BUFF
			call hd_write
			pop edx
			cmp al, 0
			jnz	.ErrClear
			mov DWORD [pit_task_ticks], 0					; clear pit-ticks 
			inc edx
			cmp edx, [fat32_sectors_per_fat]
			jc	.Next
	; create root-dir
			mov ebx, fat32_CreatingRootDirTxt
			call gstdio_draw_text
			mov DWORD [FAT32_SECTOR_BUFF+8], FAT32_END_OF_CLUSTER_MARKER
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov ecx, [fat32_fat_begin_lba]
			mov ebx, 1
			mov eax, FAT32_SECTOR_BUFF
			call hd_write
			cmp al, 0
			jz	.RootClus
			mov ebx, fat32_HDWriteFATRootErrTxt
			call gstdio_draw_text
			jmp .Back
		; clear Cluster-buffer
.RootClus	cld
			mov edi, FAT32_CLUSTER_BUFF
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			mov eax, 512
			mul ebx
			mov ecx, eax
			shr ecx, 2						; /4 to get DWORDS
			xor eax, eax
			rep stosd
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ebx, [fat32_root_dir_cluster]
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, eax
			xor ebp, ebp
			mov eax, FAT32_CLUSTER_BUFF
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			call hd_write
			cmp al, 0
			jz	.Init
			mov ebx, fat32_HDWriteClusRootErrTxt
			call gstdio_draw_text
			jmp	.Back
.Init		call fat32_init
			jmp .Back
.ErrClear	mov ebx, fat32_HDWriteFATClearErrTxt
			call gstdio_draw_text
.Back		popad
			ret


; IN: fat32_dirs_num
; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res
fat32_read_curr_dir:
			cmp BYTE [fat32_dirs_num], 0
			jz	.Root
			xor ebx, ebx
			mov bl, BYTE [fat32_dirs_num]
			shl	ebx, 2
			mov edx, fat32_dir_clusters
			add edx, ebx
			mov ebx, [edx]
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
			mov ecx, eax
			jmp fat32_read_clus
.Root		mov ebx, [fat32_root_dir_cluster]
			mov ecx, [fat32_root_dir_lba]
; IN: ECX(LBALo)
; OUT: FAT32_CLUSTER_BUF (data)
fat32_read_clus:
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov eax, FAT32_CLUSTER_BUFF
			push ebx
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
;push edx
;call gstdio_new_line
;mov edx, ecx
;call gstdio_draw_hex
;call gstdio_new_line
;mov edx, ebx
;call gstdio_draw_hex
;pop edx
;call gstdio_new_line
;call gutil_press_a_key
			call hd_read
			pop ebx
			mov BYTE [fat32_hd_res], al
			ret


; IN: fat32_name_addr, FAT32_CLUSTER_BUFF
; OUT: fat32_res(1 if available, so the name doesn't exist in the current dir)
; checks if the given name exists in the current directory
fat32_is_name_available:
			pushad
			mov DWORD [fat32_res], 1
.Start		mov esi, FAT32_CLUSTER_BUFF
.Chk		cmp BYTE [esi], 0
			jz	.Back
	; IN: ESI (addrname1), EDI(addrofname2)
	; OUT: EAX(0 if found)
			mov edi, [fat32_name_addr]
			call fat32_check_names
			cmp al, 0
			jz	.Found
.Inc		add esi, FAT32_DIR_ENTRY_LEN
			mov ebx, esi
			sub ebx, FAT32_CLUSTER_BUFF
			shr	ebx, 5										; /32
			cmp ebx, [fat32_dir_entries_per_cluster_num]
			jc	.Chk										; jump if unsigned smaller
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			call fat32_get_next_cluster_num
			cmp DWORD [fat32_res], 1
			jz	.ChkEOM
			mov ebx, fat32_GetNextClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
.ChkEOM		cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			je	.Back			; error
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
			mov ecx, eax
			call fat32_read_clus
			cmp BYTE [fat32_hd_res], 0
			jz	.Start
			mov ebx, fat32_ReadClusErrTxt
			call gstdio_draw_text
			jmp	.Back
.Found		mov DWORD [fat32_res], 0
.Back		popad
			ret


; Adds Dir-entry for the given file or folder. If filesize is not zero, then gets-free-cluster (just one) and sets it to Dir-entry.
; If end-of-dir marker (i.e. zero) was overwritten, then adds end-of-dir marker in the next Dir-entry, 
; adding a new cluster to the chain of directory clusters, if necessary. Writes directory cluster(s) to disk.
; IN: ESI(addr of entry), EBX(directory-clusternum), ECX(filesizeinbytes), fat32_name_addr(with size at the front), fat32_attr_byte, fat32_add_dir_end
; OUT: EBX(cluster_num (adds first cluster of file (if filesize is not zero), or directory), fat32_res
;!?In case of error: clear FAT-entry!? And fix dir-entry!?
fat32_create_dir_entry:
			pushad
			mov DWORD [fat32_res], 0
			push ecx
			; copy name to Dir-entry
			mov eax, esi
			mov esi, [fat32_name_addr]
			mov edi, eax
			xor ecx, ecx
			mov cl, [esi]
			inc ecx
			rep movsb
			mov esi, eax
.Attrib		pop ecx
			mov al, [fat32_attr_byte]
			mov BYTE [esi+FAT32_DE_ATTRIB], al
			push ebx
	;	OUT: BX (7:4:5 Y:M:D)
			call gutil_get_date	
			mov [esi+FAT32_DE_DATE_CR], bx
			mov [esi+FAT32_DE_DATE_LAST], bx
			mov [esi+FAT32_DE_DATE_WR], bx
			pop ebx
		;if filesize is zero ---> don't allocate free cluster!
			cmp ecx, 0
			jne	.AddClus
			mov DWORD [esi+FAT32_DE_CLUS_NUM], 0
			mov DWORD [esi+FAT32_DE_SIZE], 0
			mov DWORD [fat32_cluster_num1], 0			; save new
			jmp .ChkEnd
	; IN: fat32_next_free_cluster_num (if UNKNOWN --> search starts from zero)
	; OUT: EBX, fat32_res
	; writes ENDCLUS to FAT
			; find a free cluster in FAT
.AddClus	push ebx							; save current clusternum (i.e. the directory's cluster)
			call fat32_get_free_cluster			; gets new cluster for the new directory or new file
			mov [fat32_cluster_num1], ebx		; save new
			pop ebx								; EBX is the current clusternum (i.e. the directory's cluster)
			cmp DWORD [fat32_res], 1
			jz	.SetClus
			mov ebx, fat32_GetFreeClusErrTxt
			call gstdio_draw_text
			jmp	.Back
.SetClus	mov DWORD [fat32_res], 0
			mov eax, [fat32_cluster_num1]
			mov [esi+FAT32_DE_CLUS_NUM], eax	; store new cluster 
			mov al, [fat32_attr_byte]
			and al, FAT32_ATTR_DIRECTORY
			jnz	.Direc
			mov [esi+FAT32_DE_SIZE], ecx
			jmp .ChkEnd
; A directory also has a size! (Normal dir should have '.' and ".." initially; rootdir is empty), but dirs are read clus-by-clus (size not used)
.Direc		mov DWORD [esi+FAT32_DE_SIZE], 0	
.ChkEnd:
			cmp BYTE [fat32_add_dir_end], 1		; end of directory was overwritten?
			jnz	.Write
			add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_CLUSTER_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]	; do we need a new cluster?
			jc	.SetEnd							; jump if smaller			(unsigned)
		; write current cluster to disk before we add a new one (i.e. cluster) for the current directory
	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, eax
			xor ebp, ebp
			mov eax, FAT32_CLUSTER_BUFF
			push ebx
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			call hd_write
			pop ebx
			cmp al, 0
			jz	.AddClus2
			mov ebx, fat32_HDWriteErrTxt
			call gstdio_draw_text
			jmp	.Back
	; IN: EBX(clusternum; eg. 2 for RootDir)
	; OUT: EBX(new clusternum)
			; add new cluster
.AddClus2	call fat32_add_new_cluster	
			cmp DWORD [fat32_res], 1
			jz	.ReadClus
			mov ebx, fat32_AddNewClusterErrTxt
			call gstdio_draw_text
			jmp	.Back
		; read new cluster
	; IN: EBX(clusternum)
	; OUT: EAX
.ReadClus	call fat32_cluster2lba
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, eax
			xor ebp, ebp
			mov eax, FAT32_CLUSTER_BUFF
			push ebx
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			call hd_read
			pop ebx
			cmp al, 0
			jz	.Set
			mov ebx, fat32_HDReadErrTxt
			call gstdio_draw_text
			jmp	.Back
.Set		mov esi, FAT32_CLUSTER_BUFF			; why?
.SetEnd		mov BYTE [esi], 0					; End of directory entries
	; IN: EBX(clusternum)
	; OUT: EAX
.Write		call fat32_cluster2lba
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, eax
			xor ebp, ebp
			mov eax, FAT32_CLUSTER_BUFF
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			call hd_write
			cmp al, 0
			jz	.Ok
			mov ebx, fat32_HDWriteErrTxt
			call gstdio_draw_text
			jmp	.Back
.Ok			mov DWORD [fat32_res], 1
.Back		popad
			mov ebx, [fat32_cluster_num1]		; the new cluster of the dir or file
			ret

; IN: EBX(clusternum; eg. 2 for RootDir)
; OUT: EBX(new clusternum)
; 1.finds free cluster in FAT
; 2.reads 1 sector from FAT (which contains the current cluster)
; 3.adds new cluster to chain
; 4.writes sector to disk
fat32_add_new_cluster:
			pushad
			mov DWORD [fat32_res], 0
			mov [fat32_cluster_num2], ebx					 ; save current clusternum
	; IN: fat32_next_free_cluster_num (if UNKNOWN --> search starts from zero)
	; OUT: EBX, fat32_res
	; writes ENDCLUS to FAT
			call fat32_get_free_cluster						; new clusternum in EBX
			cmp DWORD [fat32_res], 1
			jz	.Calc
			mov ebx, fat32_GetFreeClusErrTxt
			call gstdio_draw_text
			jmp	.Back
.Calc		mov DWORD [fat32_res], 0
			mov edi, ebx									; new clusternum in EDI
			mov ebx, [fat32_cluster_num2]
			mov ebp, ebx
			and ebp, FAT32_OFFSET_WITHIN_SECTOR_MASK
			shl ebp, 2										; the offset is in DWORDS
			shr ebx, 7										; EBX: sectornumber in FAT
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
			call fat32_read_fat	
			cmp BYTE [fat32_hd_res], 0
			jz	.Wr
			mov ebx, fat32_ReadFATErrTxt
			call gstdio_draw_text
			jmp	.Back
.Wr			mov esi, FAT32_SECTOR_BUFF
			add esi, ebp
			mov [esi], edi									; set new clusternum in FAT-table
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
			call fat32_write_fat
			cmp BYTE [fat32_hd_res], 0
			jz	.Ok
			mov ebx, fat32_WriteFATErrTxt
			call gstdio_draw_text
			jmp	.Back
.Ok			mov [fat32_cluster_num2], edi					 ; set new clusternum
			mov DWORD [fat32_res], 1
.Back		popad
			mov ebx, [fat32_cluster_num2]					; set new clusternum
			ret


; IN: fat32_next_free_cluster_num (if UNKNOWN --> search starts from zero)
; OUT: EBX, fat32_res
; finds free(i.e. 0) in FAT, and writes EndOfClusterMarker to it
fat32_get_free_cluster:	
			push edx
			push esi
			mov DWORD [fat32_res], 0
			mov ebx, [fat32_next_free_cluster_num]
			cmp ebx, FAT32_FSINFO_UNKNOWN
			jne	.Find
	; IN: EBX(cluster-num to start the search from); EDX(sectornum to end the search)
	; OUT: EBX(first free cluster-num); ESI(ptr to cluster-num in sector), fat32_hd_res
			mov ebx, 3							; skip first two unused clusternum and rootdirclusternum
.Find		mov edx, [fat32_sectors_per_fat]
			call fat32_find_free_cluster_num
			cmp BYTE [fat32_hd_res], 0
			jz	.Comp
			mov ebx, fat32_FindFreeClusErrTxt
			call gstdio_draw_text
			jmp	.Back
.Comp		cmp ebx, edx	;[fat32_sectors_per_fat]
			jc	.Write						; jump if unsigned smaller
			cmp DWORD [fat32_next_free_cluster_num], FAT32_FSINFO_UNKNOWN
			jne	.SearchBeg
			mov ebx, fat32_NextFreeClusNumUnkErrTxt
			call gstdio_draw_text
			jmp	.Back
	;!!!???
		; Search from the beginning of FAT till next_free_cluster_num, if no free was found and search not started from the beginning
	; IN: EBX(cluster-num to start the search from); EDX(sectornum to end the search)
	; OUT: EBX(first free cluster-num); ESI(ptr to cluster-num in sector), fat32_hd_res
.SearchBeg	mov ebx, 3							; skip first two unused clusternum and rootdirclusternum
			mov edx, [fat32_next_free_cluster_num]
			call fat32_find_free_cluster_num
			cmp BYTE [fat32_hd_res], 0
			jz	.Comp2
			mov ebx, fat32_FindFreeClusErrTxt
			call gstdio_draw_text
			jmp	.Back
.Comp2		cmp ebx, edx	;[fat32_next_free_cluster_num]
			je	.Back
.Write		mov DWORD [esi], FAT32_END_OF_CLUSTER_MARKER
;call gstdio_new_line
;push esi
;push ecx
;mov esi, FAT32_SECTOR_BUFF
;mov ecx, 128
;call gutil_mem_dump
;pop ecx
;pop esi
;call gstdio_new_line
;call gutil_press_a_key
			push ebx
			shr	ebx, 7										; to get sector-number
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
			call fat32_write_fat
			pop ebx
			cmp BYTE [fat32_hd_res], 0
			jz	.Ok
			mov ebx, fat32_WriteFATErrTxt
			call gstdio_draw_text
			jmp	.Back
.Ok			mov DWORD [fat32_res], 1
.Back		pop esi
			pop edx
			ret


; IN: EBX(cluster-num to start the search from); EDX(sectornum to end the search)
; OUT: EBX(first free cluster-num); ESI(ptr to cluster-num in sector), fat32_hd_res
fat32_find_free_cluster_num:
			push edx
			push ebp
			mov ebp, ebx
			and ebp, FAT32_OFFSET_WITHIN_SECTOR_MASK
			shl ebp, 2										; the offset is in DWORDS
			shr	ebx, 7										; to get sector-number
			mov esi, FAT32_SECTOR_BUFF
			add esi, ebp
			cmp ebx, 0										; 0th sectorNum?
			jnz	.NextSect
			cmp ebp, 8										; if in the 0th sector, check if greater than the two unused sectorNums
			jnc	.NextSect									; jump if unsigned greater or equal
			push eax										; this makes search from the rootdirclusnum, if <2 was given
			mov eax, 8
			sub eax, ebp
			add esi, eax
			pop eax
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
.NextSect	call fat32_read_fat
			cmp BYTE [fat32_hd_res], 0
			jz	.ClearPIT
			mov ebx, fat32_ReadFATErrTxt
			call gstdio_draw_text
			jmp	.Back
.ClearPIT	mov DWORD [pit_task_ticks], 0					; clear pit-ticks 
.Read		cmp DWORD [esi], 0
			je	.Fnd
			add esi, 4
			cmp esi, FAT32_SECTOR_BUFF+FAT32_BYTES_SECTOR
			jne	.Read
			mov esi, FAT32_SECTOR_BUFF
			inc ebx
			cmp ebx, edx
			jc	.NextSect
			jmp .Back
.Fnd		shl ebx, 7						; *128 (clusternumbers per sector)
			mov edx, esi
			sub edx, FAT32_SECTOR_BUFF
			shr edx, 2						; /4 to get DWORDs
			add ebx, edx					; ebx contains the cluster_num to be set
;push ebx
;mov ebx, fat32_Dbg2FreeClusNUmTxt
;call gstdio_draw_text
;pop ebx
;push eax
;mov eax, ebx
;call gstdio_draw_dec
;pop eax
;call gstdio_new_line
.Back		pop ebp
			pop edx
			ret


; IN: EBX(clusternum to read)
; OUT: ECX(number of consecutive clusters); EDX(the next clusternumber after the consecutive ones)
; i.e. in case of clusters: 3,4,5,6,9,10	(3 is from the dir-entry, the rest are in FAT)
;	calling this func with clusnum 3, it returns with ECX(4) and EDX(9)
fat32_get_consec_cluster_num:
			push eax
			push ebx
			mov eax, ebx						; save orig clusternum
			xor ecx, ecx
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
.Next		call fat32_get_next_cluster_num	
			cmp DWORD [fat32_res], 1
			jz	.Inc
			mov ebx, fat32_GetNextClusNumErrTxt
			call gstdio_draw_text
			jmp	.Back
.Inc		inc ecx
			cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			je	.Back
			cmp cx, [fat32_max_clusters_num_per_word]		; == 65535/sectors_per_cluster ? (only 16-bit sectorcnt is used)
			je	.Back
			push ecx
			add ecx, eax
			cmp ebx, ecx
			pop ecx
			je	.Next
.Back		mov edx, ebx
			pop ebx
			pop eax
			ret


; IN: EBX(clusternum)
; OUT: EAX
fat32_cluster2lba:
			push ebx
			push edx
			sub ebx, 2
			xor eax, eax
			mov al, [fat32_sectors_per_cluster]
			mul ebx
			add eax, [fat32_cluster_begin_lba]
			pop edx
			pop ebx
			ret


; IN: EBX(clusternum)
; OUT: fat32_res, EBX(clusternum)
fat32_get_next_cluster_num:
			mov DWORD [pit_task_ticks], 0					; clear pit-ticks (Or call PAUSE!?)
			push eax
			push ecx
			push edx
			push ebp
			push esi
			mov DWORD [fat32_res], 0
			mov ebp, ebx
			and ebp, FAT32_OFFSET_WITHIN_SECTOR_MASK
			shl ebp, 2										; the offset is in DWORDS
			shr ebx, 7										; EBX: sectornumber in FAT
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
			call fat32_read_fat
			cmp BYTE [fat32_hd_res], 0
			jz	.Calc
			mov ebx, fat32_ReadFATErrTxt
			call gstdio_draw_text
			jmp	.Back
.Calc:
			mov esi, FAT32_SECTOR_BUFF
			add esi, ebp
			mov ebx, [esi]
			mov DWORD [fat32_res], 1
.Back		pop esi
			pop ebp
			pop edx
			pop ecx
			pop eax
			ret


; IN: EBX(lbaLo)
; OUT: fat32_hd_res(0 if ok)
fat32_read_fat:
			mov BYTE [fat32_hd_res], 1
			cmp ebx, [fat32_curr_sector_num]				; Sector already in memory? If yes don't read. Note that we don't check lbaHI
			je	.Ok
			mov [fat32_curr_sector_num], ebx				; Note that we don't save lbaHI
			push eax
			push ebx
			push ecx
			push ebp
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, ebx
			add ecx, [fat32_fat_begin_lba]
			xor ebp, ebp
			mov eax, FAT32_SECTOR_BUFF
			mov ebx, 1
			call hd_read
			mov BYTE [fat32_hd_res], al
			sub ecx, [fat32_fat_begin_lba]			; !?
			pop ebp
			pop ecx
			pop ebx
			pop eax
			jmp .Back
.Ok			mov BYTE [fat32_hd_res], 0
.Back		ret


; IN: EBX(lbaLo)
; OUT: fat32_hd_res(0 if ok)
fat32_write_fat:
			push eax
			push ebx
			push ecx
			push ebp
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, ebx
			add ecx, [fat32_fat_begin_lba]
			xor ebp, ebp
			mov eax, FAT32_SECTOR_BUFF
			mov ebx, 1
			call hd_write
			mov BYTE [fat32_hd_res], al
			sub ebx, [fat32_fat_begin_lba]
			pop ebp
			pop ecx
			pop ebx
			pop eax
			ret


fat32_read_fsinfo:
			pushad
			mov DWORD [fat32_res], 0
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, [fat32_partition_lba_begin]
			add ecx, [fat32_fsinfo_sector]
			xor ebp, ebp
			mov eax, FAT32_SECTOR_BUFF
			mov ebx, 1
			call hd_read
			cmp al, 0
			jz	.Prep
			mov ebx, fat32_HDReadErrTxt
			call gstdio_draw_text
			jmp	.Back
.Prep		mov [fat32_curr_sector_num], ebx					; Note that we don't save lbaHI
			mov esi, FAT32_SECTOR_BUFF
			add esi, FAT32_FSINFO_LEADSIG_OFFS
			cmp DWORD [esi], FAT32_FSINFO_LEADSIG
			jne	.Back
			sub esi, FAT32_FSINFO_LEADSIG_OFFS
			add esi, FAT32_FSINFO_STRUCSIG_OFFS
			cmp DWORD [esi], FAT32_FSINFO_STRUCSIG
			jne	.Back
			sub esi, FAT32_FSINFO_STRUCSIG_OFFS
			add esi, FAT32_FSINFO_TRAILSIG_OFFS
			cmp DWORD [esi], FAT32_FSINFO_TRAILSIG
			jne	.Back
			sub esi, FAT32_FSINFO_TRAILSIG_OFFS
			add esi, FAT32_FSINFO_FREECLUSTERCNT_OFFS
			mov eax, [esi]
			mov [fat32_free_clusters_cnt], eax				; should we check the value aginst disk size?
			sub esi, FAT32_FSINFO_FREECLUSTERCNT_OFFS
			add esi, FAT32_FSINFO_NEXTFREECLUSTERNUM_OFFS
			mov eax, [esi]
			; check value
			cmp eax, FAT32_FSINFO_UNKNOWN
			je	.StoreCN
			mov ebx, [fat32_sectors_per_fat]					; check
			shl	ebx, 7											; *128 to get number of clusters
			cmp eax, ebx
			jnc	.Back
.StoreCN	mov [fat32_next_free_cluster_num], eax
			mov DWORD [fat32_res], 1
.Back		popad
			ret


fat32_write_fsinfo:
			pushad
			mov DWORD [fat32_res], 0
			mov eax, [fat32_free_clusters_cnt]
			mov ebx, [fat32_next_free_cluster_num]
			call fat32_read_fsinfo
			cmp DWORD [fat32_res], 1
			jz	.Prep
			mov ebx, fat32_ReadFSInfoErrTxt
			call gstdio_draw_text
			jmp	.Back
.Prep		mov DWORD [fat32_res], 0
			mov [fat32_free_clusters_cnt], eax
			mov [fat32_next_free_cluster_num], ebx
			mov esi, FAT32_SECTOR_BUFF
			add esi, FAT32_FSINFO_FREECLUSTERCNT_OFFS
			mov [esi], eax
			sub esi, FAT32_FSINFO_FREECLUSTERCNT_OFFS
			add esi, FAT32_FSINFO_NEXTFREECLUSTERNUM_OFFS
			mov [esi], ebx
			; write
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov ecx, [fat32_partition_lba_begin]
			add ecx, [fat32_fsinfo_sector]
			mov eax, FAT32_SECTOR_BUFF
			mov ebx, 1
			call hd_write
			cmp al, 0
			jz	.Wr
			mov ebx, fat32_HDWriteErrTxt
			call gstdio_draw_text
			jmp	.Back
			; write copy of FSInfo-sector
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
.Wr			xor ebp, ebp
			mov ecx, [fat32_partition_lba_begin]
			add ecx, [fat32_copy_boot_sector]
			inc ecx
			mov eax, FAT32_SECTOR_BUFF
			mov ebx, 1
	; IN: EAX(lbaHI), EBX(LBALO), ECX(memaddr), EDX(number of sectors)
			call hd_write
			cmp al, 0
			jz	.Ok
			mov ebx, fat32_HDWriteErrTxt
			call gstdio_draw_text
			jmp	.Back
.Ok			mov DWORD [fat32_res], 1
.Back		popad
			ret


; IN: ESI(ptr to entry), EBP(date-offset in record)
fat32_print_date:
			pushad
			xor eax, eax
			mov ax, [esi+ebp]
			shr ax, 9
			add eax, 1980
			call gstdio_draw_dec
			xor ebx, ebx
			mov bl, FAT32_DATE_SEPARATOR_CHAR
			call gstdio_draw_char
			mov ax, [esi+ebp]
			and ax, 0x01E0
			shr ax, 5
			call gstdio_draw_dec
			mov bl, FAT32_DATE_SEPARATOR_CHAR
			call gstdio_draw_char
			mov ax, [esi+ebp]
			and ax, 0x001F
			call gstdio_draw_dec
			mov ebx, ' '
			call gstdio_draw_char
			popad
			ret


; IN: ESI (addrname1), EDI(addrofname2)
; OUT: EAX(0 if found)
fat32_check_names:
			push ebx
			push esi
			push edi
			; check length
			xor eax, eax
			mov al, [esi+FAT32_DE_NAME]
			cmp [edi], al
			jnz .Back
			; check chars
			mov edx, esi
.NextChar	inc edx
			inc edi
			mov bl, [edx]
			cmp BYTE [edi], bl
			jnz	.Back
			dec al
			cmp al, 0
			jnz	.NextChar
.Back		pop	edi
			pop esi
			pop ebx
			ret


; IN: EBX(clusternum)
; OUT: fat32_res; fat32_is_folder_empty(1 if empty)
; checks if folder is empty
fat32_check_folder:
			pushad
			mov DWORD [fat32_res], 0
			mov BYTE [fat32_is_folder_empty], 1
.ReadClus	mov [fat32_cluster_num1], ebx
 	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
			mov ecx, eax
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov eax, FAT32_DBG_TMP_BUFF
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			call hd_read
			cmp al, 0
			jz	.Set
			mov ebx, fat32_HDReadErrTxt
			call gstdio_draw_text
			jmp	.Back
.Set		mov esi, FAT32_DBG_TMP_BUFF
.Check		cmp BYTE [esi], 0								; end of dir-entries?
			jz	.Ok
			cmp BYTE [esi], FAT32_DELETED_ENTRY
			jz	.Inc
			mov BYTE [fat32_is_folder_empty], 0
			jmp .Back
.Inc		add esi, FAT32_DIR_ENTRY_LEN
			mov edx, esi
			sub edx, FAT32_DBG_TMP_BUFF
			shr	edx, 5										; /32
			cmp edx, [fat32_dir_entries_per_cluster_num]
			jc	.Check
			mov ebx, [fat32_cluster_num1]
	; get_next_cluster_num
	; IN: EBX(clusternum)
	; OUT: fat32_res, EBX(clusternum)
			mov ebx, [fat32_cluster_num1]
			mov DWORD [pit_task_ticks], 0					; clear pit-ticks (Or call PAUSE!?)
			mov ebp, ebx
			and ebp, FAT32_OFFSET_WITHIN_SECTOR_MASK
			dec ebp
			shl ebp, 2										; the offset is in DWORDS
			shr ebx, 7										; EBX: sectornumber in FAT
	; read_fat
	; IN: EBX(lbaLo)
	; OUT: fat32_hd_res(0 if ok)
	; hd_read
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, ebx
			add ecx, [fat32_fat_begin_lba]
			xor ebp, ebp
			mov eax, FAT32_DBG_TMP_BUFF2
			mov ebx, 1
			call hd_read
			cmp al, 0
			jz	.Calc
			mov ebx, fat32_ReadFATErrTxt
			call gstdio_draw_text
			jmp	.Back
.Calc		mov esi, FAT32_DBG_TMP_BUFF2
			add esi, ebp
			mov ebx, [esi]
			cmp ebx, FAT32_END_OF_CLUSTER_MARKER
			jne	.ReadClus
.Ok			mov DWORD [fat32_res], 1
.Back		popad
			ret


; IN: -
; OUT: fat32_res
fat32_save_path:
			pushad
			mov DWORD [fat32_res], 0
			cmp BYTE [fat32_fs_inited], 1
			jnz	.Back
			mov eax, [fat32_dirs_num]
			mov [fat32_dirs_num_saved], eax
			mov esi, fat32_dir_clusters
			mov edi, fat32_dir_clusters_saved
			mov ecx, FAT32_MAX_DIR_DEPTH_NUM
			rep movsd
			mov DWORD [fat32_res], 1
.Back		popad
			ret


; IN: -
; OUT: fat32_res
fat32_restore_path:
			pushad
			mov DWORD [fat32_res], 0
			cmp BYTE [fat32_fs_inited], 1
			jnz	.Back
			mov eax, [fat32_dirs_num_saved]
			mov [fat32_dirs_num], eax
			mov esi, fat32_dir_clusters_saved
			mov edi, fat32_dir_clusters
			mov ecx, FAT32_MAX_DIR_DEPTH_NUM
			rep movsd
			mov DWORD [fat32_res], 1
.Back		popad
			ret


;*******************************************************************

; For debugging
; IN: EBX(FAT-sector num; 0 is the first one), EDX(length (<512))
; OUT: fat32_res (1 is ok)
; Dump FAT-table
fat32_show_fat:
			pushad
			mov DWORD [fat32_res], 0
			push edx
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			mov ecx, [fat32_fat_begin_lba]
			add ecx, ebx
			xor ebp, ebp
			mov eax, FAT32_DBG_TMP_BUFF
			mov ebx, 1
			call hd_read
			cmp al, 0
			pop edx
			jz	.Ok
			mov ebx, fat32_Dbg2HDReadErrTxt
			call gstdio_draw_text
			jmp .Back
.Ok			call gstdio_new_line
			mov esi, FAT32_DBG_TMP_BUFF
			mov ecx, edx
			cmp ecx, FAT32_BYTES_SECTOR
			jna	.Dump
			mov ecx, FAT32_BYTES_SECTOR
.Dump		call gutil_mem_dump
			mov DWORD [fat32_res], 1
.Back		popad
			ret


; For debugging
; IN: EDX(length)
; OUT: EBX(clusternum), dump of FAT32_CLUSTER_BUFF; fat32_res
; for the current directory
fat32_show_curr_cluster:
			pushad
			mov DWORD [fat32_res], 0
			push edx
		; IN: fat32_dirs_num
		; OUT: EBX(clusternum), FAT32_CLUSTER_BUFF, fat32_hd_res(1 is ok)
			call fat32_read_curr_dir
			cmp BYTE [fat32_hd_res], 0
			pop	edx
			jz	.Show
			mov ebx, fat32_ReadClusErrTxt
			call gstdio_draw_text
			jmp	.Back
.Show		call gstdio_new_line
			mov [fat32_cluster_num1], ebx
			mov esi, FAT32_CLUSTER_BUFF
			mov ecx, edx
			xor eax, eax
			mov al, [fat32_sectors_per_cluster]
			shl eax, 9
			cmp ecx, eax
			jna	.Dump
			mov ecx, eax
.Dump		call gutil_mem_dump
			mov DWORD [fat32_res], 1
.Back		popad
			mov ebx, [fat32_cluster_num1]
			ret


; For debugging
; IN: EBX(clusternum); EDX(length)
; OUT: dump of FAT32_CLUSTER_BUFF; fat32_res
fat32_show_cluster:
			pushad
			mov DWORD [fat32_res], 0
			push edx
 	; IN: EBX(clusternum)
	; OUT: EAX
			call fat32_cluster2lba
			mov ecx, eax
	; IN: ECX: lbaLo, EBP: lbaHi, EBX: sectorcnt, EAX: memaddr
	; OUT: AL (0 indicates success)
			xor ebp, ebp
			mov eax, FAT32_CLUSTER_BUFF
			xor ebx, ebx
			mov bl, [fat32_sectors_per_cluster]
			call hd_read
			cmp al, 0
			pop edx
			jz	.Show
			mov ebx, fat32_HDReadErrTxt
			call gstdio_draw_text
			jmp	.Back
.Show		call gstdio_new_line
			mov esi, FAT32_CLUSTER_BUFF
			mov ecx, edx
			xor eax, eax
			mov al, [fat32_sectors_per_cluster]
			shl eax, 9
			cmp ecx, eax
			jna	.Dump
			mov ecx, eax
.Dump		call gutil_mem_dump
			mov DWORD [fat32_res], 1
.Back		popad
			ret


; For debugging
; IN: -
; OUT: fat32_res
fat32_show_pwd:
			pushad
			mov DWORD [fat32_res], 1
			call gstdio_new_line
			mov ebx, fat32_Dbg2DirsNumTxt
			call gstdio_draw_text
			xor eax, eax
			mov al, [fat32_dirs_num]
			call gstdio_draw_dec
			call gstdio_new_line
			; dir-names
			xor ecx, ecx
			mov ebx, FAT32_PATH_BUFF
;call gstdio_new_line
;push esi
;push ecx
;mov esi, FAT32_PATH_BUFF
;mov ecx, 100
;call gutil_mem_dump
;pop ecx
;pop esi
;call gstdio_new_line
;call gutil_press_a_key
.NextName	call gstdio_draw_text
			push ebx
			mov ebx, ' '
			call gstdio_draw_char
			pop ebx
			add ebx, FAT32_MAX_NAME_LEN
			inc ecx
			cmp cl, [fat32_dirs_num]
			jna	.NextName
			call gstdio_new_line
			; cluster-numbers
			xor ecx, ecx
			mov eax, fat32_dir_clusters
.NextClus	mov edx, [eax]
			call gstdio_draw_hex
			mov ebx, ' '
			call gstdio_draw_char
			add eax, 4
			inc ecx
			cmp cl, [fat32_dirs_num]
			jna	.NextClus
			call gstdio_new_line
			popad
			ret


section .data

fat32_disktotalsectors dd 0

; partition
fat32_partition_type_code	db	0
fat32_partition_lba_begin	dd	0
fat32_partition_sectors_cnt	dd	0

; VolumeID
fat32_bytes_per_sector		dw	0		; these variables(6 bytes) will be filled by "rep movsb"
fat32_sectors_per_cluster	db	0
fat32_reserved_sectors_num	dw	0
fat32_fats_num				db	0

fat32_sectors_per_fat	dd	0
fat32_root_dir_cluster	dd	0
fat32_fsinfo_sector		dd	0
fat32_copy_boot_sector	dd	0

fat32_max_clusters_num_per_word	dw	0

;	fat_begin_lba(DWORD)			= Partition_LBA_begin + Number_Of_Reserved_Sectors
;	cluster_begin_lba(DWORD)		= Partition_LBA_begin + Number_Of_Reserved_Sectors + (Number_Of_FATs * Sectors_Per_FAT)
;	sectors_per_cluster(BYTE)		= Sectors Per Cluster
;	root_dir_first_cluster(DWORD)	= Root Dir First Cluster
fat32_fat_begin_lba			dd	0
fat32_cluster_begin_lba		dd	0
fat32_root_dir_lba			dd	0
;lba_addr = cluster_begin_lba + (cluster_number - 2) * sectors_per_clusters

fat32_dir_entries_per_cluster_num	dd	0

fat32_cluster_num1	dd	0			; to store clusternum temporarily
fat32_cluster_num2	dd	0			; to store clusternum temporarily

fat32_next_clusnum	dd 0

fat32_fs_inited	db	0

fat32_memaddr		dd 0
fat32_filesize		dd 0
fat32_hdlba			dd 0

fat32_long_list	db 0

; path-related variables
fat32_dir_clusters	times FAT32_MAX_DIR_DEPTH_NUM dd 0
fat32_dirs_num	db 0
fat32_dir_clusters_saved	times FAT32_MAX_DIR_DEPTH_NUM dd 0
fat32_dirs_num_saved	db 0

fat32_sfn_buff	times 13 db	0		; the name+'.'+extension will be copied here (spaces skipped) with a zero put at the end

fat32_sectorcnt	dd	0

fat32_file_size		dd 0
fat32_clusters_cnt	dd 0

fat32_curr_sector_num	dd -1						; we don't want to load the same sector several times

fat32_res		dd	0			; holds result
fat32_hd_res	db	0

fat32_attr_byte	db 0

fat32_add_dir_end	db 0

fat32_name_addr	dd 0
fat32_new_name_addr	dd 0

fat32_folderTxt	db "d ", 0

fat32_is_folder_empty	db 0

; FSInfo structure (sector 1 and its copy is in sector 7)
fat32_free_clusters_cnt		dd 0
fat32_next_free_cluster_num	dd FAT32_FSINFO_UNKNOWN

; for fat32_fsinfo
fat32_FSInfoTxt				db "FSInfo(data in hex):", 0x0A, 0
fat32_TotalSectorsTxt		db "Total sectors: ", 0
fat32_FATBeginLBATxt		db "FAT begin LBA: ", 0
fat32_ClustersBeginLBATxt	db "Clusters begin LBA: ", 0
fat32_SectorsPerFATTxt		db "Sectors per FAT: ", 0
fat32_SectorsPerClusterTxt	db "Sectors per cluster: ", 0
fat32_FreeClustersCountTxt	db "Free clusters count: ", 0
fat32_FirstFreeClusterNumTxt	db "Most recently allocated clusternum: ", 0

; errors
fat32_HDReadErrTxt			db "FAT32: HD read error!", 0x0A, 0
fat32_SectorByteCntErrTxt	db "FAT32: Sector byte-count error!", 0x0A, 0
fat32_FATCntErrTxt			db "FAT32: FAT count error!", 0x0A, 0
fat32_SigErrTxt				db "FAT32: Signature error!", 0x0A, 0
fat32_ReadFSInfoErrTxt		db "FAT32: ReadFSInfo error!", 0x0A, 0
fat32_FSNotInitedErrTxt		db "FAT32: FS not inited error!", 0x0A, 0
fat32_ReadFATErrTxt			db "FAT32: Read FAT error!", 0x0A, 0
fat32_ReadClusErrTxt		db "FAT32: Read Cluster error!", 0x0A, 0
fat32_GetNextClusNumErrTxt	db "FAT32: Get next cluster number error!", 0x0A, 0
fat32_ReadCurrDirErrTxt		db "FAT32: Read current directory error!", 0x0A, 0
fat32_GetConsecClusNumErrTxt	db "FAT32: Get consec cluster num error!", 0x0A, 0
fat32_NameAlreadyExistsErrTxt	db "FAT32: Name already exists error!", 0x0A, 0
fat32_CreateDirEntryErrTxt	db "FAT32: Create directory entry error!", 0x0A, 0
fat32_HDWriteErrTxt			db "FAT32: HD write error!", 0x0A, 0
fat32_AddNewClusterErrTxt	db "FAT32: Add new cluster error!", 0x0A, 0
fat32_WriteFSInfoErrTxt		db "FAT32: Write FSInfo error!", 0x0A, 0
fat32_GetFreeClusErrTxt		db "FAT32: Get free cluster error!", 0x0A, 0
fat32_FindFreeClusErrTxt	db "FAT32: Find free cluster error!", 0x0A, 0
fat32_FreeClusCntUnkTxt		db "FAT32: Free clusters-count unknown, error!", 0x0A, 0
fat32_NoFreeClusErrTxt		db "FAT32: No free cluster error!", 0x0A, 0
fat32_NameNotAvailErrTxt	db "FAT32: Name not available error!", 0x0A, 0
fat32_EndOfClusMarkerFndTxt	db "FAT32: End of cluster marker found error!", 0x0A, 0
fat32_NameTooLongErrTxt		db "FAT32: Name too long error!", 0x0A, 0
fat32_WriteFATErrTxt		db "FAT32: Write FAT error!", 0x0A, 0
fat32_NextFreeClusNumUnkErrTxt	db "FAT32: NextFreeClusterNumber is unknown error!", 0x0A, 0

fat32_HDWriteMBRErrTxt		db "FAT32: write MBR error", 0x0A, 0
fat32_HDWriteVBRErrTxt		db "FAT32: write VBR error", 0x0A, 0
fat32_HDWriteFSInfoErrTxt	db "FAT32: write FSInfo error", 0x0A, 0
fat32_HDWriteFATClearErrTxt	db "FAT32: write FAT clear error", 0x0A, 0
fat32_HDWriteFATRootErrTxt	db "FAT32: write FAT root-cluster error", 0x0A, 0
fat32_HDWriteClusRootErrTxt	db "FAT32: write root-cluster error", 0x0A, 0

fat32_FolderNotEmptyErrTxt	db "Folder is not empty error", 0x0A, 0

fat32_DataInDecTxt			db "(Data in decimal)", 0x0A, 0
fat32_HDCapacityMBTxt		db "HD-capacity (in MB): ", 0
fat32_SectorsPerCluster2Txt	db "Sectors per cluster: ", 0
fat32_SectorsPerFAT2Txt		db "Sectors per FAT: ", 0
fat32_WritingMBRTxt			db "Writing MBR", 0x0A, 0
fat32_WritingVBRToSectorTxt	db "Writing VBR to sector: ", 0
fat32_WritingFSInfoToSectorTxt	db "Writing FSInfo to sector: ", 0
fat32_ErasingFATTxt			db "Erasing FAT ...", 0x0A, 0
fat32_CreatingRootDirTxt	db "Creating root-dir", 0x0A, 0


%endif


