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


# ================================


def to_hpf(i):
    """
    Converts the integer, i, to an equivlant half-prescion float.
    
      >>> to_hpf(6)
      17920
      >>> hpf_split(to_hpf(6))
      (512, 17, 0)
      >>> to_hpf(-11)
      51584
      >>> hpf_split(to_hpf(-11))
      (384, 18, 1)
      >>> to_hpf(0)
      0
    """
    assert (i < 1024), "integer too large"

    if i == 0:
        return 0

    mantissa = abs(i)
    exp = 24
    sign = (1 - i//abs(i))//2
    
    while mantissa & (2 ** 9) == 0:
        mantissa <<= 1
        exp -= 1
    
    mantissa = (mantissa << 1) & (2 ** 10 - 1)
    return hpf_join(mantissa, exp, sign)


def hpf_str(num):
    """
    Generates a string representation of the half-prescion float, num.

      >>> hpf_str(to_hpf(6))
      '0 10001 1000000000'
      >>> hpf_str(to_hpf(-11))
      '1 10010 0110000000'
    """
    (mantissa, exp, sign) = hpf_split(num)
    return str(sign) + " " + bin(exp)[2:].zfill(5) + " " + bin(mantissa)[2:].zfill(10)


def hpf_to_val(num):
    """
    calculates the value of an hpf, num, as a python float.
    """
    m, e, s = hpf_split(num)
    return (-1 if s else 1) * (m/(2 ** 10) + 1) * (2 ** (e - 15))


# ================================


def i_div(n, d):
    q = 0
    r = 0

    for pos in reversed(range(32)):
        r <<= 1
        r |= (n & 2 ** pos) >> pos
        if r >= d:
            r -= d
            q |= 2 ** pos
    return q


def hpf_gt(d1, d2):
    """
    compares the absolute value of two half prescion floats.

      >>> gt = lambda x, y : hpf_gt(to_hpf(x), to_hpf(y)) 
      >>> gt(32, 2)
      True
      >>> gt(3, 2)
      True
      >>> gt(4, 5)
      False
      >>> gt(-9, 2)
      True
    """
    (m1, e1, s1) = hpf_split(d1)
    (m2, e2, s2) = hpf_split(d2)

    # compare the exponents
    if e1 > e2:
        return True
    elif e2 > e1:
        return False
    # if the exponents are equal compare the mantisas
    elif m1 > m2:
        return True
    else:
        return False


# ================================


def hpf_add(d1, d2):
    """
    adds two half prescion floats, d1 and d2.

      >>> add = lambda x, y : hpf_str(hpf_add(to_hpf(x), to_hpf(y)))
      >>> add(3, 2)
      '0 10001 0100000000'
      >>> add(17, 5)
      '0 10011 0110000000'
      >>> add(20, -7)
      '0 10010 1010000000'
      >>> add(-12, 15)
      '0 10000 1000000000'
    """
    (m1, e1, s1) = hpf_split(d1)
    (m2, e2, s2) = hpf_split(d2)

    # add the implied ones
    m1 += 2 ** 10
    m2 += 2 ** 10
    
    # additive identity
    if not (d1 and d2):
        return d1 + d2

    # additive inverses
    if m1 == m2 and e1 == e2 and s1 ^ s2:
        return 0

    # ensure d1 is greater than d2
    if hpf_gt(d2, d1):
        (m1, e1, s1, m2, e2, s2) = (m2, e2, s2, m1, e1, s1) 

    # if one num is negative then multiply
    # the mantisa of the smaller number by
    # negative one
    if s1 ^ s2:
        m2 *= -1

    m = m1 + (m2 >> e1 - e2)
    e = e1
    s = s1

    # adjust for forward carry
    if m & 2 ** 11 and d1 and d2:
        e += 1
        m >>= 1
    
    # adjust for backward carry
    while s1 ^ s2 and not(m & 2 ** 10):
        e -= 1
        m <<= 1

    return hpf_join(m, e, s)


def hpf_prod(d1, d2):
    """
    calculates the product of two half prescion floats, d1 and d2.

      >>> prod = lambda x, y : hpf_prod(to_hpf(x), to_hpf(y))
    """
    (m1, e1, s1) = hpf_split(d1)
    (m2, e2, s2) = hpf_split(d2)

    #add back the implied ones
    m1 += 2 ** 10
    m2 += 2 ** 10

    # multiply by zero
    if not(d1 and d2):
        return 0

    m = m1 * m2
    e = e1 + e2 - 15
    s = s1 ^ s2
    
    # adjust exponent
    if m & 2 ** 21 != 0:
        e += 1

    # align the implied 1
    while (m >> 11 != 0):
        m >>= 1
    
    return hpf_join(m, e, s)


def hpf_div(d1, d2):
    """
    divides two half prescion float, d1 and d2.

      >>> divide = lambda x, y : hpf_div(to_hpf(x), to_hpf(y))
    """
    assert (d2 != 0), "inverse of zero"

    (m1, e1, s1) = hpf_split(d1)
    (m2, e2, s2) = hpf_split(d2)

    # add back the implied ones
    m1 += 2 ** 10
    m2 += 2 ** 10

    # to prevent loss of accuracy adjust the 
    # numerator before division
    m1 <<= 10

    m  = i_div(m1, m2)
    e = e1 - e2 + 15
    s = s1 ^ s2
    
    # align the implied 1 and adjust exponent
    while not (m & 2 ** 10):
        m <<= 1
        e -= 1

    return hpf_join(m, e, s)


if __name__ == "__main__":
    import doctest
    doctest.testmod()

