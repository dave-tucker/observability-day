PROGRAM Triangle
    IMPLICIT NONE
    INTEGER :: n
    INTEGER,PARAMETER :: seed = 86456
    REAL :: a, b, c, Area
    CALL RANDOM_INIT(.true., .true.)

    CALL SRAND(seed)
    DO
        CALL RANDOM_NUMBER(a)
        a = FLOAT(INT(a * 1000))
        b = a
        c = a
        PRINT *, 'Computing Area of Triangles'
        PRINT *, 'Values: ', a, b, c
        PRINT *, 'Area: ', Area(a, b, c)
        CALL SLEEP(1)
    END DO
    PRINT *, 'Done'
END PROGRAM Triangle

FUNCTION Area(x,y,z)
    IMPLICIT NONE
    !GCC$ ATTRIBUTES CDECL ::  Area
    REAL :: Area            ! function type
    REAL, INTENT( IN ) :: x, y, z
    REAL :: theta, height
    theta = ACOS((x**2+y**2-z**2)/(2.0*x*y))
    height = x*SIN(theta); Area = 0.5*y*height
END FUNCTION Area
