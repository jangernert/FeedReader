#ifndef lists_h
#define lists_h       1

void start_uls(int nooutput, int spaces, int breite, int error, int zeilen_len);
void end_uls(int nooutput, int spaces, int breite, int error, int zeilen_len);
void start_ols(int nooutput, int spaces, int breite, int error, int zeilen_len);
void end_ols(int nooutput, int spaces, int breite, int error, int zeilen_len);
void start_lis(int nooutput, int spaces, int breite, int error, int zeilen_len);
void end_lis();
void start_dl(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len);
void end_dl(int nooutput, int spaces, int paragraph, int breite, int error, int zeilen_len);
void start_dt(int nooutput, int spaces, int breite, int error, int zeilen_len);
void end_dt();
void start_dd(int nooutput, int spaces, int breite, int error, int zeilen_len);
void end_dd(int spaces);

#endif 
