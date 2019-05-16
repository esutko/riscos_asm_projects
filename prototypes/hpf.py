# Half-precision floating-point arithmetic
# By Ellis W R Sutko with documentation by Jeff Elkner
#
# Half-precision floating-point format is a 16 bit binary floating-point
# number format. See:
# https://en.wikipedia.org/wiki/Half-precision_floating-point_format
#
# This module contains Python functions for manipulating values of this type.
#


def mask(num, length):
    """
    Return the low order length bits of the number num.

      >>> mask(10, 3)    # The low order 3 bits of 1010
      2
      >>> mask(711, 3)   # The low order 3 bits of 11000111
      7
      >>> mask(726, 5)   # The low order 5 bits of 11010110
      22
    """
    return num & (2 ** length - 1)


def hpf_split(num):
    """
    Split the 16 bits of a half-precision floating-point number into its
    parts.

      >>> hpf_split(9221)
      (5, 9, 0)
    """
    mantissa = num & (2 ** 10 - 1)
    exp = (num & ((2 ** 5 - 1) << 10)) >> 10
    sign = (num & (2 ** 15)) >> 15

    return mantissa, exp, sign


def hpf_join(mantissa, exp, sign):
    """
    Join the mantissa, exponent, and sign values into a 16 bit half-precision
    floating-point number.
    
      >>> hpf_join(5, 9, 0)
      9221
    """
    return mask(mantissa, 10) + (mask(exp, 5) << 10) + (mask(sign, 1) << 15)


# ================


def hpf_str(num):
    """
    Generates a string representation of the half-prescion float, num.

    >>> hpf_str(to_hpf(6))
    '0 10001 1000000000'
    """
    (mantissa, exp, sign) = hpf_split(num)
    return str(sign) + " " + bin(exp)[2:].zfill(5) + " " + bin(mantissa)[2:].zfill(10)


def to_hpf(i):
    """
    Converts the integer, i, to an equivlant half-prescion float.
    
    >>> to_hpf(6)
    17920
    >>> hpf_split(to_hpf(6))
    (512, 17, 0)
    """
    assert (i < 1024), "integer too large"
    if i == 0:
        return 15 << 15

    mantissa = abs(i)
    exp = 24
    sign = (1 - i//abs(i))//2
    
    while mantissa & (2 ** 9) == 0:
        mantissa <<= 1
        exp -= 1
    
    mantissa = (mantissa << 1) & (2 ** 10 - 1)
    return hpf_join(mantissa, exp, sign)


# ================


def hpf_add(d1, d2):
    (m1, e1, s1) = hpf_split(d1)
    (m2, e2, s2) = hpf_split(d2)

    if e2 > e1:
        (m1, e1, s1, m2, e2, s2) = (m2, e2, s2, m1, e1, s1)
    

    m = 0
    e = 0
    s = 0

    return hpf_join(m, e, s)


def hpf_prod(d1, d2):
    (m1, e1, s1) = hpf_split(d1)
    (m2, e2, s2) = hpf_split(d2)    
    m1 += 2 ** 10
    m2 += 2 ** 10

    m = m1 * m2
    e = e1 + e2 - 15
    s = s1 ^ s2
    
    if m & 2 ** 21 != 0:
        e += 1

    while (m >> 11 != 0):
        m >>= 1
    
    return hpf_join(m, e, s)


def hpf_div(d1, d2):
    assert (num != 0), "inverse of zero"

    (m1, e1, s1) = hpf_split(num)
    (m2, e2, s2) = hpf_split(d2)
    m1 += 2 ** 10
    m2 += 2 ** 10

    m  = 0
    e = e1 - e2 + 15
    s = s1 ^ s2

    return hpf_join(m, e, s)


def test(a, b, show=False):
    if show:
        print(hpf_prod(to_hpf(a), to_hpf(b)) == to_hpf(a * b))
        print(hpf_str(hpf_prod(to_hpf(a), to_hpf(b))))
        print(hpf_str(to_hpf(a * b)))
    return hpf_prod(to_hpf(a), to_hpf(b)) == to_hpf(a * b)


for x in range(1, 32):
    for y in range(1, 32):
        if not test(x, y):
            print((x, y))
