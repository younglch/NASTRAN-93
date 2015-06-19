      SUBROUTINE SHSTSS (NUMPX,ELID,IGRID,THIKNS,Z12,G,EPSCSI,STEMP,    
     1                   TBAR,G2ALFB,BENDNG,IDR)        
C        
C     TO CALCULATE SHELL ELEMENT STRESSES FOR A 2-D FORMULATION BASE.   
C     COMPOSITE LAYER STRESSES ARE NOT CALCULATED IN THIS ROUTINE.      
C        
C        
C     INPUT :        
C           NUMPX  - NUMBER OF EVALUATION POINTS        
C           ELID   - ELEMENT ID        
C           IGRID  - ARRAY IF EXTERNAL GRID IDS        
C           THIKNS - EVALUATION POINT THICKNESSES        
C           Z12    - EVALUATION POINT FIBER DISTANCES        
C           G      - 6X6 STRESS-STRAIN MATRIX        
C           EPSCSI - CORRECTED STRAINS AT EVALUATION POINTS        
C           STEMP  - TEMPERATURE DATA FOR STRESS RECOVERY        
C           TBAR   - AVERAGE ELEMENT TEMPERATURE        
C           G2ALFB - MATRIX USED IN RECORRECTING OF STRESSES        
C           BENDNG - INDICATES THE PRESENCE OF BENDING BEHAVIOR        
C           IDR    - REORDERING ARRAY BASED ON EXTERNAL GRID POINT ID'S 
C          /TMPDAT/- TEMPERATURE-RELATED LOGICAL FLAGS        
C          /OUTREQ/- OUTPUT REQUEST LOGICAL FLAGS        
C        
C     OUTPUT:        
C           STRESSES ARE PLACED AT THE PROPER LOCATION IN /SDR2X7/.     
C        
C        
C     THE STRESS OUTPUT DATA BLOCK (UAI CODE)        
C        
C     ADDRESS    DESCRIPTIONS        
C        
C        1       ELID        
C     -------------------------------------------------------        
C        2       'CNTR'        
C        3       LOWER FIBER DISTANCE        
C      4 - 10    STRESSES FOR LOWER POINTS AT ELEMENT CENTER POINT      
C       11       UPER  FIBER DISTANCE        
C     12 - 18    STRESSES FOR UPPER POINTS AT ELEMENT CENTER POINT      
C       19       FIRST GRID POINT NUMBER        
C     20 - 35    REPEAT  3 TO 18 ABOVE FOR FIRST  GRID POINT        
C     36 - 52    REPAET 19 TO 36 ABOVE FOR SECOND GRID POINT        
C     53 - 69    REPAET 19 TO 36 ABOVE FOR THIRD  GRID POINT        
C        
C        
C     THE STRESS OUTPUT DATA BLOCK AT ELEMENT CENTER ONLY, COSMIC       
C        
C     ADDRESS    DESCRIPTIONS        
C        
C        1       ELID        
C     -------------------------------------------------------        
C        2       LOWER FIBER DISTANCE        
C      3 -  9    STRESSES FOR LOWER POINTS AT ELEMENT CENTER POINT      
C       10       UPER  FIBER DISTANCE        
C     11 - 17    STRESSES FOR UPPER POINTS AT ELEMENT CENTER POINT      
C        
C        
      LOGICAL         GRIDS, VONMS, LAYER, STRCUR,BENDNG,STSREQ,STNREQ, 
     1                GRIDSS,VONMSS,LAYERS,FORREQ,TEMPER,TEMPP1,TEMPP2, 
     2                COSMIC        
      INTEGER         IGRID(1),NSTRES(1),IDR(1),ELID        
      REAL            STEMP(2)        
      REAL            THIKNS(1),Z12(2,1),G(6,6),EPSCSI(6,1),G2ALFB(3,1),
     1                S1MAT(3,3),S2MAT(3,3),SIGMA(3),EPSS,SIGMAP(4),    
     2                THICK,T3OV12,FIBER,CONST,TBAR,TPRIME,TSUBI        
      COMMON /SDR2X7/ DUM71(100),STRES(100),FORSUL(200),STRIN(100)      
      COMMON /TMPDAT/ TEMPER,TEMPP1,TEMPP2        
      COMMON /OUTREQ/ STSREQ,STNREQ,FORREQ,STRCUR,GRIDS,VONMS,LAYER     
     1,               GRIDSS,VONMSS,LAYERS        
      EQUIVALENCE     (NSTRES(1),STRES(1))        
      DATA    COSMIC, EPSS  / .TRUE., 1.0E-11 /        
C        
C        
C     ELEMENT CENTER POINT COMPUTAION ONLY FOR COSMIC,        
C     I.E. THE CALLER SHOULD PASS 1 IN NUMPX FOR COSMIC, 4 FOR UAI      
C        
      NUMP = NUMPX        
      IF (COSMIC) NUMP = 1        
C        
      NSTRES(1) = ELID        
C        
C     START THE LOOP ON EVALUATION POINTS        
C        
      NUMP1 = NUMP - 1        
      DO 300 INPLAN = 1,NUMP        
      THICK  = THIKNS(INPLAN)        
      T3OV12 = THICK*THICK*THICK/12.0        
C        
      ISTRES = 1        
      IF (COSMIC) GO TO 140        
C        
      ISTRES = (INPLAN-1)*17 + 2        
      NSTRES(ISTRES) = INPLAN - 1        
      IF (.NOT.GRIDS .OR. INPLAN.LE.1) GO TO 130        
      DO 100 INPTMP = 1,NUMP1        
      IF (IDR(INPTMP) .EQ. IGRID(INPLAN)) GO TO 120        
  100 CONTINUE        
      CALL ERRTRC ('SHSTSS  ',100)        
  120 ISTRES = INPTMP*17 + 2        
      NSTRES(ISTRES) = IGRID(INPLAN)        
  130 IF (INPLAN .EQ. 1) NSTRES(ISTRES) = IGRID(INPLAN)        
C        
C        
C     START THE LOOP ON FIBERS        
C        
  140 DO 280 IZ = 1,2        
      FIBER = Z12(IZ,INPLAN)        
      STRES(ISTRES+1) = FIBER        
      CONST = 12.0*FIBER/THICK        
C        
C     CREATE [S1] AND [S2]        
C        
      DO 150 I = 1,3        
      DO 150 J = 1,3        
      S1MAT(I,J) = G(I  ,J  ) - CONST*G(I,J+3)        
      S2MAT(I,J) = G(I+3,J+3) - CONST*G(I,J+3)        
  150 CONTINUE        
C        
C     EVALUATE STRESSES AT THIS FIBER DISTANCE        
C        
      DO 170 I = 1,3        
      SIGMA(I) = 0.0        
      DO 160 J = 1,3        
      SIGMA(I) = SIGMA(I) + S1MAT(I,J)*EPSCSI(J  ,INPLAN)        
     1         - FIBER    * S2MAT(I,J)*EPSCSI(J+3,INPLAN)        
  160 CONTINUE        
  170 CONTINUE        
C        
C     IF TEMPERATURES ARE PRESENT, RECORRECT STRESSES FOR THERMAL       
C     STRESSES RESULTING FROM TEMPERATURE VALUES AT FIBER DISTANCES.    
C        
      IF (.NOT.TEMPER .OR. .NOT.BENDNG) GO TO 250        
      IF (.NOT.TEMPP1) GO TO 180        
      TPRIME = STEMP(2   )        
      TSUBI  = STEMP(2+IZ)        
      IF (ABS(TSUBI) .LT. EPSS) GO TO 250        
      TSUBI  = TSUBI - TPRIME*FIBER        
      GO TO 220        
C        
  180 IF (.NOT.TEMPP2) GO TO 250        
      TSUBI = STEMP(4+IZ)        
      IF (ABS(TSUBI) .LT. EPSS) GO TO 250        
      DO 200 IST = 1,3        
      SIGMA(IST) = SIGMA(IST) - STEMP(IST+1)*FIBER/T3OV12        
  200 CONTINUE        
C        
  220 TSUBI = TSUBI - TBAR        
      DO 230 ITS = 1,3        
      SIGMA(ITS) = SIGMA(ITS) - TSUBI*G2ALFB(ITS,INPLAN)        
  230 CONTINUE        
C        
C     CLEANUP AND SHIP CORRECTED STRESSES        
C        
  250 DO 260 ITS = 1,3        
      IF (ABS(SIGMA(ITS)) .LE. EPSS) SIGMA(ITS) = 0.0        
      STRES(ISTRES+1+ITS) = SIGMA(ITS)        
  260 CONTINUE        
C        
C     CALCULATE PRINCIPAL STRESSES        
C        
      CALL SHPSTS (SIGMA,VONMS,SIGMAP)        
      STRES(ISTRES+5) = SIGMAP(1)        
      STRES(ISTRES+6) = SIGMAP(2)        
      STRES(ISTRES+7) = SIGMAP(3)        
      STRES(ISTRES+8) = SIGMAP(4)        
C        
      ISTRES = ISTRES + 8        
  280 CONTINUE        
  300 CONTINUE        
C        
      RETURN        
      END        