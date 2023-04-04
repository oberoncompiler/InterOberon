MODULIS Viļņi;
IMPORTĒ Ievade, Izvade;
MAINĪGIE N, D, i, ī, t, garums: VESELAIS;
SĀKUMS
  Izvade.Litera('N'); Izvade.Litera('=');
  Ievade.Veselais(N);
  Izvade.Litera('D'); Izvade.Litera('=');
  Ievade.Veselais(D);
  i := 0;
  ATKĀRTOT
    ī := 1;
    KAMĒR ī <= 2 * D - 1 DARĪT
      JA ī < D TAD garums := ī
      BETJA ī = D TAD garums := D
      CITĀDI garums := 2 * D - ī
      BEIGAS;
      t := 0;
      KAMĒR t < garums DARĪT
        Izvade.Litera('=');
        t := t + 1
      BEIGAS;
      Izvade.Pārnese;
      ī := ī + 1
    BEIGAS;
    JA i # N - 1 TAD
      Izvade.Litera('~');
      Izvade.Pārnese;
    BEIGAS;
    i := i + 1
  LĪDZ i = N
BEIGAS Viļņi.
