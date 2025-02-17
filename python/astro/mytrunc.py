
def truncate_float(float_number, decimal_places):
    multiplier = 10 ** decimal_places
    return int(float_number * multiplier) / multiplier

float3 = 3.14159
result = truncate_float(float3, 2)

print(result)

