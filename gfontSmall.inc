
;*************************************************
;	gfont.inc
;		- 10*15 Font-bitmap
;
;*************************************************

%ifndef __GFONT__
%define __GFONT__


bits 32


; 10*15 Font Bitmap
gfont_charr:
; ***  (Space)
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** !
db	0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** "
db	0x00, 0x00, 0x33, 0x00, 0x33, 0x00, 0x33, 0x00, 0x33, 0x00, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** #
db	0x00, 0x00, 0x19, 0x80, 0x19, 0x80, 0x7f, 0xc0, 0x7f, 0xc0, 0x19, 0x80, 0x19, 0x80, 0x7f, 0xc0, 0x7f, 0xc0, 0x33, 0x00, 0x33, 0x00, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** $
db	0x00, 0x00, 0x0c, 0x00, 0x3f, 0x80, 0x6c, 0x80, 0x6c, 0x00, 0x3f, 0x00, 0x1f, 0x80, 0x0c, 0x80, 0x4d, 0x80, 0x7f, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** %
db	0x00, 0x00, 0x30, 0x00, 0x48, 0x00, 0x48, 0x80, 0x31, 0x80, 0x03, 0x00, 0x0e, 0x00, 0x18, 0x00, 0x33, 0x00, 0x64, 0x80, 0x04, 0x80, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** &
db	0x00, 0x00, 0x1c, 0x00, 0x32, 0x00, 0x32, 0x00, 0x12, 0x00, 0x0c, 0x00, 0x1d, 0x80, 0x33, 0x80, 0x66, 0x00, 0x4f, 0x00, 0x79, 0x80, 0x30, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** '
db	0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** (
db	0x00, 0x00, 0x06, 0x00, 0x0e, 0x00, 0x18, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x18, 0x00, 0x0e, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** )
db	0x00, 0x00, 0x18, 0x00, 0x1c, 0x00, 0x06, 0x00, 0x03, 0x00, 0x03, 0x00, 0x03, 0x00, 0x03, 0x00, 0x03, 0x00, 0x06, 0x00, 0x1c, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** *
db	0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x4c, 0x80, 0x7f, 0x80, 0x1e, 0x00, 0x1e, 0x00, 0x7f, 0x80, 0x4c, 0x80, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** +
db	0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x3f, 0x00, 0x3f, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** ,
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x07, 0x00, 0x0f, 0x00, 0x1c, 0x00, 0x18, 0x00, 0x00, 0x00
; *** -
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3f, 0x80, 0x3f, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** .
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x00, 0x0e, 0x00, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** /
db	0x00, 0x00, 0x00, 0x00, 0x01, 0x80, 0x01, 0x80, 0x03, 0x00, 0x03, 0x00, 0x06, 0x00, 0x06, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x18, 0x00, 0x18, 0x00, 0x30, 0x00, 0x30, 0x00, 0x00, 0x00
; *** 0
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x73, 0x80, 0x63, 0x80, 0x65, 0x80, 0x69, 0x80, 0x69, 0x80, 0x71, 0x80, 0x73, 0x80, 0x3f, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 1
db	0x00, 0x00, 0x0e, 0x00, 0x1e, 0x00, 0x36, 0x00, 0x26, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x1f, 0x80, 0x1f, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 2
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x33, 0x00, 0x01, 0x80, 0x01, 0x80, 0x07, 0x00, 0x0e, 0x00, 0x18, 0x00, 0x30, 0x00, 0x3f, 0x80, 0x3f, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 3
db	0x00, 0x00, 0x3e, 0x00, 0x3f, 0x00, 0x01, 0x80, 0x01, 0x80, 0x1f, 0x00, 0x1f, 0x00, 0x01, 0x80, 0x01, 0x80, 0x01, 0x80, 0x3f, 0x80, 0x3e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 4
db	0x00, 0x00, 0x02, 0x00, 0x06, 0x00, 0x0e, 0x00, 0x1e, 0x00, 0x36, 0x00, 0x66, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 5
db	0x00, 0x00, 0x7f, 0x00, 0x7f, 0x00, 0x60, 0x00, 0x60, 0x00, 0x7e, 0x00, 0x7f, 0x00, 0x03, 0x00, 0x03, 0x00, 0x07, 0x00, 0x7e, 0x00, 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 6
db	0x00, 0x00, 0x1f, 0x00, 0x3f, 0x80, 0x31, 0x80, 0x60, 0x00, 0x60, 0x00, 0x6f, 0x00, 0x7f, 0x80, 0x60, 0x80, 0x31, 0x80, 0x1f, 0x80, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 7
db	0x00, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x01, 0x80, 0x03, 0x00, 0x03, 0x00, 0x06, 0x00, 0x0c, 0x00, 0x18, 0x00, 0x18, 0x00, 0x30, 0x00, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 8
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x61, 0x00, 0x61, 0x00, 0x3f, 0x00, 0x1e, 0x00, 0x63, 0x00, 0x63, 0x00, 0x63, 0x00, 0x3f, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** 9
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x31, 0x80, 0x31, 0x80, 0x3f, 0x80, 0x0f, 0x80, 0x01, 0x80, 0x01, 0x80, 0x31, 0x80, 0x3f, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** :
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** ;
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x07, 0x00, 0x0f, 0x00, 0x1c, 0x00, 0x18, 0x00, 0x00, 0x00
; *** <
db	0x00, 0x00, 0x00, 0x00, 0x01, 0x80, 0x0f, 0x80, 0x3c, 0x00, 0x60, 0x00, 0x60, 0x00, 0x38, 0x00, 0x1e, 0x00, 0x07, 0x80, 0x01, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** =
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3f, 0x80, 0x3f, 0x80, 0x00, 0x00, 0x00, 0x00, 0x3f, 0x80, 0x3f, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** >
db	0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x78, 0x00, 0x3e, 0x00, 0x07, 0x80, 0x01, 0x80, 0x07, 0x80, 0x1e, 0x00, 0x78, 0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** ?
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x63, 0x80, 0x61, 0x80, 0x21, 0x80, 0x03, 0x00, 0x0f, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** @
db	0x00, 0x00, 0x0e, 0x00, 0x1f, 0x00, 0x31, 0x80, 0x67, 0x80, 0x6f, 0x80, 0x6c, 0x80, 0x6c, 0x80, 0x37, 0x80, 0x33, 0x80, 0x18, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** A
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x33, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x7f, 0x80, 0x7f, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** B
db	0x00, 0x00, 0x7e, 0x00, 0x7f, 0x00, 0x41, 0x80, 0x41, 0x80, 0x7f, 0x80, 0x7f, 0x00, 0x43, 0x00, 0x41, 0x80, 0x41, 0x80, 0x7f, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** C
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x31, 0x80, 0x61, 0x80, 0x60, 0x80, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x71, 0x80, 0x3f, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** D
db	0x00, 0x00, 0x7e, 0x00, 0x7f, 0x00, 0x63, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x63, 0x80, 0x7f, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** E
db	0x00, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x40, 0x00, 0x40, 0x00, 0x7e, 0x00, 0x7e, 0x00, 0x40, 0x00, 0x40, 0x00, 0x40, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** F
db	0x00, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x60, 0x00, 0x60, 0x00, 0x7e, 0x00, 0x7e, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** G
db	0x00, 0x00, 0x1f, 0x00, 0x3f, 0x80, 0x70, 0x00, 0x60, 0x00, 0x60, 0x00, 0x63, 0x80, 0x63, 0x80, 0x61, 0x80, 0x71, 0x80, 0x3f, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** H
db	0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x7f, 0x80, 0x7f, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** I
db	0x00, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** J
db	0x00, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x26, 0x00, 0x3e, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** K
db	0x00, 0x00, 0x60, 0x80, 0x61, 0x80, 0x63, 0x00, 0x66, 0x00, 0x6c, 0x00, 0x78, 0x00, 0x78, 0x00, 0x6c, 0x00, 0x66, 0x00, 0x63, 0x00, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** L
db	0x00, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** M
db	0x00, 0x00, 0x61, 0x80, 0x73, 0x80, 0x7f, 0x80, 0x6d, 0x80, 0x6d, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** N
db	0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x71, 0x80, 0x79, 0x80, 0x6d, 0x80, 0x6d, 0x80, 0x67, 0x80, 0x63, 0x80, 0x63, 0x80, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** O
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x3f, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** P
db	0x00, 0x00, 0x7e, 0x00, 0x7f, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x7f, 0x00, 0x7e, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** Q
db	0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x00, 0x3f, 0x80, 0x1f, 0x80, 0x03, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** R
db	0x00, 0x00, 0x7e, 0x00, 0x7f, 0x00, 0x61, 0x80, 0x61, 0x80, 0x7f, 0x80, 0x7f, 0x00, 0x66, 0x00, 0x63, 0x00, 0x63, 0x00, 0x63, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** S
db	0x00, 0x00, 0x1f, 0x00, 0x3f, 0x80, 0x60, 0x80, 0x60, 0x00, 0x7e, 0x00, 0x3f, 0x00, 0x01, 0x80, 0x01, 0x80, 0x41, 0x80, 0x7f, 0x00, 0x3e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** T
db	0x00, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** U
db	0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x33, 0x80, 0x3f, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** V
db	0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x33, 0x00, 0x33, 0x00, 0x33, 0x00, 0x13, 0x00, 0x12, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** W
db	0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x6d, 0x80, 0x6d, 0x80, 0x3f, 0x00, 0x3f, 0x00, 0x3f, 0x00, 0x3b, 0x00, 0x33, 0x00, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** X
db	0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x33, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x1e, 0x00, 0x33, 0x00, 0x33, 0x00, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** Y
db	0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x33, 0x00, 0x33, 0x00, 0x33, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** Z
db	0x00, 0x00, 0x3f, 0x80, 0x7f, 0x80, 0x01, 0x80, 0x03, 0x00, 0x06, 0x00, 0x0c, 0x00, 0x18, 0x00, 0x30, 0x00, 0x60, 0x00, 0x7f, 0x80, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** [
db	0x00, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x18, 0x00, 0x18, 0x00, 0x18, 0x00, 0x18, 0x00, 0x18, 0x00, 0x18, 0x00, 0x18, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** "\"
db	0x00, 0x00, 0x60, 0x00, 0x60, 0x00, 0x30, 0x00, 0x18, 0x00, 0x18, 0x00, 0x0c, 0x00, 0x06, 0x00, 0x06, 0x00, 0x03, 0x00, 0x01, 0x80, 0x01, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** ]
db	0x00, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x06, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** ^
db	0x00, 0x00, 0x0c, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x33, 0x00, 0x33, 0x00, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** _
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x00, 0x00
; *** `
db	0x00, 0x00, 0x18, 0x00, 0x18, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x06, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** a
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3d, 0x80, 0x7f, 0x80, 0x63, 0x80, 0x63, 0x80, 0x63, 0x80, 0x63, 0x80, 0x7f, 0x80, 0x3d, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** b
db	0x00, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x7f, 0x00, 0x7f, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x7f, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** c
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3e, 0x00, 0x7f, 0x80, 0x61, 0x80, 0x60, 0x00, 0x60, 0x00, 0x61, 0x80, 0x7f, 0x80, 0x3e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** d
db	0x00, 0x00, 0x01, 0x80, 0x01, 0x80, 0x01, 0x80, 0x01, 0x80, 0x3f, 0x80, 0x7f, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x3f, 0x80, 0x1f, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** e
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x00, 0x31, 0x80, 0x61, 0x80, 0x7f, 0x00, 0x7e, 0x00, 0x40, 0x00, 0x21, 0x80, 0x1f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** f
db	0x00, 0x00, 0x07, 0x00, 0x0f, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x3f, 0x00, 0x3f, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** g
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x80, 0x3f, 0x80, 0x73, 0x80, 0x61, 0x80, 0x73, 0x80, 0x7f, 0x80, 0x3f, 0x80, 0x01, 0x80, 0x61, 0x80, 0x3f, 0x00, 0x1f, 0x00, 0x00, 0x00
; *** h
db	0x00, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x7e, 0x00, 0x7f, 0x00, 0x73, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** i
db	0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1c, 0x00, 0x1c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x1e, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** j
db	0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x3c, 0x00, 0x3c, 0x00, 0x18, 0x00, 0x00, 0x00
; *** k
db	0x00, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x61, 0x80, 0x67, 0x80, 0x7c, 0x00, 0x7c, 0x00, 0x66, 0x00, 0x63, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** l
db	0x00, 0x00, 0x1c, 0x00, 0x1c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0e, 0x00, 0x0f, 0x80, 0x07, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** m
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6d, 0x80, 0x7e, 0x80, 0x76, 0x80, 0x64, 0x80, 0x64, 0x80, 0x64, 0x80, 0x64, 0x80, 0x64, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** n
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x6e, 0x00, 0x7f, 0x00, 0x71, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** o
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x73, 0x80, 0x61, 0x80, 0x61, 0x80, 0x73, 0x80, 0x3f, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** p
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x00, 0x7f, 0x80, 0x61, 0x80, 0x61, 0x80, 0x7f, 0x80, 0x7f, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x00, 0x00
; *** q
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x80, 0x3f, 0x80, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x3f, 0x80, 0x1f, 0x80, 0x01, 0x80, 0x01, 0x80, 0x01, 0x80, 0x00, 0x00
; *** r
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x66, 0x00, 0x7f, 0x80, 0x79, 0x80, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** s
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3f, 0x00, 0x61, 0x00, 0x78, 0x00, 0x1f, 0x00, 0x03, 0x00, 0x43, 0x00, 0x7f, 0x00, 0x1c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** t
db	0x00, 0x00, 0x18, 0x00, 0x18, 0x00, 0x18, 0x00, 0x7e, 0x00, 0x7e, 0x00, 0x18, 0x00, 0x18, 0x00, 0x18, 0x00, 0x1c, 0x00, 0x0f, 0x80, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** u
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x00, 0x63, 0x00, 0x63, 0x00, 0x63, 0x00, 0x63, 0x00, 0x63, 0x00, 0x7f, 0x00, 0x3d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** v
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x33, 0x00, 0x33, 0x00, 0x12, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** w
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x61, 0x80, 0x6d, 0x80, 0x6d, 0x80, 0x3f, 0x00, 0x33, 0x00, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** x
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x33, 0x00, 0x0c, 0x00, 0x1e, 0x00, 0x32, 0x00, 0x61, 0x80, 0x61, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** y
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x80, 0x61, 0x80, 0x33, 0x00, 0x3f, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x38, 0x00, 0x30, 0x00, 0x00, 0x00
; *** z
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x80, 0x3f, 0x80, 0x07, 0x00, 0x1e, 0x00, 0x38, 0x00, 0x60, 0x00, 0x7f, 0x80, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** {
db	0x00, 0x00, 0x0c, 0x00, 0x1c, 0x00, 0x30, 0x00, 0x30, 0x00, 0x18, 0x00, 0x18, 0x00, 0x30, 0x00, 0x18, 0x00, 0x18, 0x00, 0x30, 0x00, 0x30, 0x00, 0x1c, 0x00, 0x0c, 0x00, 0x00, 0x00
; *** |
db	0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00
; *** }
db	0x00, 0x00, 0x0c, 0x00, 0x0e, 0x00, 0x03, 0x00, 0x03, 0x00, 0x06, 0x00, 0x06, 0x00, 0x01, 0x00, 0x06, 0x00, 0x06, 0x00, 0x03, 0x00, 0x03, 0x00, 0x0e, 0x00, 0x0c, 0x00, 0x00, 0x00
; *** ~
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3d, 0x80, 0x77, 0x80, 0x63, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** Up-arrow
db	0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x1e, 0x00, 0x3f, 0x00, 0x3f, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** Down-arrow
db	0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x0c, 0x00, 0x3f, 0x00, 0x3f, 0x00, 0x1e, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** Right-arrow
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x07, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x07, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; *** Left-arrow
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x00, 0x38, 0x00, 0x7f, 0x80, 0x7f, 0x80, 0x38, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


%endif


