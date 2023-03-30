MODULIS Abc;
IMPORTĒ Ievade, Izvade;
MAINĪGIE no, līdz: VESELAIS;
  burts: LITERA;
  i: VESELAIS;
SĀKUMS (* Programma izvada burtus no 'no' līdz 'līdz' *)
  Izvade.Litera('N'); Izvade.Litera('o');
  Izvade.Litera(':'); Izvade.Litera(' ');
  Ievade.Veselais(no);

  Izvade.Litera('L'); Izvade.Litera('ī'); Izvade.Litera('d');
  Izvade.Litera('z'); Izvade.Litera(':'); Izvade.Litera(' ');
  Ievade.Veselais(līdz);
  Izvade.Pārnese;

  JA (no < 0) VAI (līdz > 65535) VAI (no > līdz) TAD
    Izvade.Litera('N'); Izvade.Litera('ē') (* Dati ir nepareizi *)
  BETJA līdz - no > 200 TAD (* Par daudz *)
    Izvade.Veselais(līdz - no, 8); Izvade.Litera('?')
  CITĀDI (* Viss kārtībā, turpinām *)
    burts := LIT(no);
    i := 1;
    KAMĒR burts <= LIT(līdz) DARĪT
      Izvade.Litera(' ');
      Izvade.Litera(burts);
      JA i = 30 TAD
        Izvade.Pārnese;
        i := 1
      CITĀDI
        i := i + 1
      BEIGAS;
      burts := LIT(ORD(burts) + 1)
    BEIGAS
  BEIGAS;
  Izvade.Pārnese
BEIGAS Abc.
