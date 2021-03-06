      SUBROUTINE GRAVL1(NVECT,GVECT,SR1,IHARM)        
C        
      INTEGER GRAVT(7),OLD,SYSBUF,SR1,BGPDT,SIL,CSTM        
      INTEGER NAME(2)        
C        
      DIMENSION  IGPCO(4),GVECT(1),VECT(3)        
C        
      COMMON /BLANK/NROWSP        
      COMMON /SYSTEM/SYSBUF        
      COMMON /ZBLPKX/ B(4),II        
CZZ   COMMON /ZZSSA1/ CORE(1)        
      COMMON /ZZZZZZ/ CORE(1)        
      COMMON  /LOADX/ N(2),BGPDT,OLD,CSTM,SIL,ISTL,NN(8),MASS        
C        
      DATA NAME/4HGRAV,4HL1  /        
C        
C ----------------------------------------------------------------------
C        
      IF (IHARM .EQ. 0) GO TO 5        
      CALL GRAVL3(NVECT,GVECT,SR1,IHARM)        
      RETURN        
    5 CONTINUE        
      LCORE=KORSZ(CORE)        
      ICM = 1        
      NZ = LCORE        
      LCORE=LCORE-SYSBUF        
      CALL GOPEN(SR1,CORE(LCORE+1),1)        
      LCORE =LCORE - SYSBUF        
      CALL GOPEN(BGPDT,CORE(LCORE+1),0)        
      OLD =0        
      LCORE =LCORE -SYSBUF        
      CALL OPEN(*10,CSTM,CORE(LCORE+1),0)        
      ICM = 0        
      CALL SKPREC(CSTM,1)        
      LCORE =LCORE-SYSBUF        
   10 CALL GOPEN(SIL,CORE(LCORE+1),0)        
      ISIL=0        
      CALL MAKMCB(GRAVT,SR1,NROWSP,2,1)        
      DO 140 ILOOP=1,NVECT        
   20 CALL READ(*200,*120,SIL,ISIL1,1,0,FLAG)        
      IF(ISIL1) 20,30,30        
   30 IL=(ILOOP-1)*3        
      ASSIGN 60 TO IOUT        
      IPONT=1        
      CALL BLDPK(1,1,GRAVT(1),0,0)        
   40 CALL READ(*200,*120,SIL,ISIL2,1,0,FLAG)        
      IF(ISIL2) 40,50,50        
   50 IF(ISIL2 -ISIL1-1) 70,60,70        
   60 ISIL1 = ISIL2        
      IPONT = IPONT+1        
      GO TO 40        
   70 CALL FNDPNT (IGPCO(1),IPONT)        
      DO 80 I=1,3        
      IN= I+IL        
   80 VECT(I) = GVECT(IN)        
      IF (IGPCO(1).NE.0) CALL BASGLB (VECT(1),VECT(1),IGPCO(2),IGPCO(1))
      DO 110 I=1,3        
      B(1)=VECT(I)        
      II = ISIL1-1+I        
      CALL ZBLPKI        
  110 CONTINUE        
      GO TO IOUT,(60,130)        
C        
C     END SIL        
C        
  120 ASSIGN 130 TO IOUT        
      IF(NROWSP-ISIL1) 70,130,70        
  130 CALL REWIND(BGPDT)        
      CALL REWIND(SIL)        
      CALL BLDPKN(GRAVT(1),0,GRAVT)        
      CALL SKPREC(SIL,1)        
      ISIL=0        
      CALL SKPREC(BGPDT,1)        
      OLD=0        
  140 CONTINUE        
      CALL CLOSE(BGPDT,1)        
      IF(ICM .EQ. 0) CALL CLOSE(CSTM,1)        
      CALL CLOSE (SIL,1)        
      CALL CLOSE (GRAVT(1),1)        
      CALL WRTTRL (GRAVT)        
      RETURN        
C        
  200 CALL MESAGE (-3,IPM,NAME)        
      RETURN        
C        
      END        
