MODULIS Pakāpes;
IMPORTĒ Ievade, Izvade;
MAINĪGIE a, x, i, rez: VESELAIS;
SĀKUMS
  Izvade.Litera('a'); Izvade.Litera('='); Ievade.Veselais(a);
  Izvade.Litera('x'); Izvade.Litera('='); Ievade.Veselais(x);
  JA x >= 0 TAD
    i := 0;
    rez := 1;
    ATKĀRTOT
      rez := rez * a;
      i := i + 1;
      Izvade.Veselais(i, 3); Izvade.Litera(')');
      Izvade.Veselais(rez, 12); Izvade.Pārnese
    LĪDZ i = x
  BEIGAS
BEIGAS Pakāpes.
