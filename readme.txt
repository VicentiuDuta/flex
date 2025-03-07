Duta_Vicentiu-Alecsandru_331CC

                                           TEMA LFA - README

Descrierea implementarii:
Programul implementeaza un parser pentru automate finite si gramatici folosind Flex. Am utilizat urmatoarele componente principale:

1. Structuri de date:
  - Variable: Contine informatii despre variabile (nume, domeniu, flag isGlobal)
  - Grammar: Stocheaza datele unei gramatici (nume, neterminali, alfabet, simbol de start, variabile locale, reguli de productie) pentru afisarea in formatul cerut
  - Automaton: Retine informatii despre un automat (nume, alfabet, stari, stari finale, starea initiala, variabile, numarul de stari, tranzitii si un flag isDeterministic)

2. Expresii regulate: Am definit regex-uri pentru recunoasterea cuvintelor cheie si a simbolurilor folosite in gramatici, automate si variabile, precum si pentru comentarii si whitespace.

3. Stari Flex: Am definit stari pentru recunoasterea datelor variabilelor, gramaticilor si automatelor, precum si pentru controlul flow-ului programului.

Flow-ul programului:
- Comentarii one-line: Am definit un regex pentru recunoasterea comentariilor pe o singura linie. Linia este ignorata, iar regula este accesibila din orice stare.

- Comentarii multi-line: Am implementat un regex pentru recunoasterea comentariilor pe mai multe linii. La intalnirea inceputului unui astfel de comentariu, starea curenta este pusa pe stiva si se trece in starea de comentariu. Iesirea din aceasta stare se face la intalnirea sfarsitului comentariului.

- Variabile: Am definit expresii regulate pentru recunoasterea tipului "variable", a numelui variabilei si a elementelor din domeniu. La intalnirea "variable", se trece in starea de citire a numelui variabilei, apoi in starea de citire a domeniului, dupa care se revine in starea "INITIAL".

- Gramatici: Am implementat expresii regulate pentru recunoasterea numelui si tipului "grammar", a neterminalilor si a elementelor alfabetului. La match-ul cu "NAME", se citeste tipul, iar pentru "grammar" se trece in starea <IN_GRAMMAR>. In aceasta stare au loc match-urile pentru fiecare element al gramaticii, datele fiind citite si stocate in stari specifice (IN_ALPHABET, IN_NONTERMINALS, IN_START_SYMBOL, etc).

Pentru productii, am folosit expresiile regulate pentru terminali si neterminali. Am utilizat un vector<pair<string, vector<string>>> pentru stocarea acestora. Am parsat mai intai membrul stang, apoi am citit "->" si am trecut la membrul drept. Am implementat o functie tokenizeProduction pentru a separa elementele din fiecare membru pe baza "&". De asemenea, am implementat o functie care determina tipul gramaticii folosind tokenii extrasi pentru ambii membri.

- Automate: Am definit expresii regulate pentru recunoasterea numelui, tipului "FiniteAutomaton", starilor si elementelor alfabetului. Match-urile pentru nume, tip si alfabet se fac similar cu cele de la gramatici. La intalnirea "states", se trece in starea "IN_AUTOMATON_STATES" pentru citirea starilor. Pentru final_states si initial_state, actiunile sunt similare. 

Pentru tranzitii, am folosit un map<string, map<string, set<string>>> pentru stocare. La match-ul cu "STATE_REGEX" din starea "IN_AUTOMATON", se trece in starea "IN_STATE_TRANSITIONS" unde se citeste caracterul pentru tranzitie. Se verifica daca acesta coincide cu numele unei variabile, caz in care este inlocuit cu domeniul variabilei. Apoi se face trecerea in starea "IN_STATE_TRANSITIONS_FINAL", unde se stocheaza tranzitiile si se verifica daca tranzitia curenta modifica tipul automatului.

Platforma de dezvoltare:
Programul a fost dezvoltat si testat pe Linux Ubuntu 22.04 LTS, folosind Flex si g++ pentru compilare.