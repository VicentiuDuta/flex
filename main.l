/* Duta_Vicentiu-Alecsandru_331CC */

%{
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <vector>
    #include <set>
    #include <map>
    #include <unordered_map>
    #include <unordered_set>

    using namespace std;

    typedef struct {
        string name;
        set<char> domain;
        bool isGlobal;
    }Variable;

    typedef struct {
        string name;
        set<string> nonterminals;
        set<char> alphabet;
        string startSymbol;
        vector<Variable> variables;
        vector<pair<string, vector<string>>> productions; // LHS -> vector of RHS alternatives
        string type; // GFR, GDC, GIC, or GR
        int numProds;
    } Grammar;

    typedef struct {
        string name;
        set<char> alphabet;
        set<string> states;
        set<string> finalStates;
        string initialState;
        vector<Variable> variables;
        int numStates;
        map <string, map<string, set<string>>> transitions; // fromState -> symbol -> toState
        bool isDeterministic;
    } Automaton;

    // Helper function to split production into tokens
    vector<string> tokenizeProduction(const string& prod) {
        vector<string> tokens;
        string currentToken;
        
        for(size_t i = 0; i < prod.length(); i++) {
            if(prod[i] == '&') {
                if(!currentToken.empty()) {
                    tokens.push_back(currentToken);
                    currentToken.clear();
                }
                continue;
            }
            
            // Start of nonterminal
            if(isupper(prod[i])) {
                if(!currentToken.empty()) {
                    tokens.push_back(currentToken);
                    currentToken.clear();
                }
                currentToken += prod[i];
                // Add following digits/letters to nonterminal
                while(i + 1 < prod.length() && isalnum(prod[i + 1])) {
                    currentToken += prod[++i];
                }
                tokens.push_back(currentToken);
                currentToken.clear();
            }
            // Terminal or other character
            else {
                if(!currentToken.empty() && isupper(currentToken[0])) {
                    tokens.push_back(currentToken);
                    currentToken.clear();
                }
                currentToken += prod[i];
            }
        }
        
        if(!currentToken.empty()) {
            tokens.push_back(currentToken);
        }
        
        return tokens;
    }

    string determineGrammarType(const Grammar& g) {
    bool isGR = true;   // GR
    bool isGIC = true;  // CIC
    bool isGDC = true;  // CDR
    
    for(const auto& prod : g.productions) {
        // Tokenize LHS
        vector<string> lhsTokens = tokenizeProduction(prod.first);
        
        
        for(const string& rhs : prod.second) {
            if(rhs == "e") continue; // Skip empty productions
            
            // Tokenize RHS
            vector<string> rhsTokens = tokenizeProduction(rhs);
            
            // Check GDC condition: |α| ≤ |β|
            if(lhsTokens.size() > rhsTokens.size()) {
                isGDC = false;
            }
            
            // Check GIC rules - LHS must be a single nonterminal
            if(lhsTokens.size() != 1 || !isupper(lhsTokens[0][0])) {
                isGIC = false;
                isGR = false;
            }
            
            // Check GR rules
            if(isGR && lhsTokens.size() == 1 && isupper(lhsTokens[0][0])) {
                bool validGR = false;
                
                if(rhsTokens.empty()) continue;
                
                // Search for the last nonterminal in RHS
                int lastNonterminalPos = -1;
                for(int i = rhsTokens.size() - 1; i >= 0; i--) {
                    if(isupper(rhsTokens[i][0])) {
                        lastNonterminalPos = i;
                        break;
                    }
                }
                
                // Case A -> w (terminals)
                if(lastNonterminalPos == -1) {
                    validGR = true;
                }
                // Case A -> wB (terminals + nonterminal)
                else {
                    bool allPreviousAreTerminals = true;
                    // Check that all symbols before the last nonterminal are terminals
                    for(int i = 0; i < lastNonterminalPos; i++) {
                        if(isupper(rhsTokens[i][0])) {
                            allPreviousAreTerminals = false;
                            break;
                        }
                    }
                    // Check that there is nothing after the last nonterminal
                    bool nothingAfterNonterminal = (lastNonterminalPos == (int) rhsTokens.size() - 1);
                    
                    validGR = allPreviousAreTerminals && nothingAfterNonterminal;
                }
                
                if(!validGR) {
                    isGR = false;
                }
            }
        }
    }
    
    if(isGR) return "GR";
    if(isGIC) return "GIC";
    if(isGDC) return "GDC";
    return "GFR";
}

    set<char> domain; // domain of current variable
    Grammar currentGrammar; // current grammar being parsed
    string currentName; // current name being parsed
    Variable currentVariable; // current variable being parsed
    string currentLHS; // current left-hand side being parsed
    string currentRHS; // current right-hand side being parsed


    Automaton currentAutomaton; // current automaton being parsed
    string currentState; // current state being parsed
    bool isVariable; // flag to check if a symbol is a variable
    set<char> currentDomain; // in case the symbol is a variable, we need to know its domain

    vector<Variable> global_variables; // global variables
%}

%option noyywrap
%option stack
%option nounput
%option noyy_top_state

/* DEFINITIONS OF STATES */
%x COMMENT
%x IN_VARIABLE_NAME
%x IN_VARIABLE_DOMAIN
%x IN_TYPE
%x IN_GRAMMAR
%x IN_AUTOMATON
%x IN_ALPHABET
%x IN_NONTERMINALS
%x IN_START_SYMBOL
%x IN_GRAMMAR_VARIABLE_NAME
%x IN_GRAMMAR_VARIABLE_DOMAIN
%x IN_PRODUCTIONS
%x IN_PRODUCTION_LHS
%x IN_PRODUCTION_RHS

%x IN_AUTOMATON_ALPHABET
%x IN_AUTOMATON_STATES
%x IN_AUTOMATON_FINAL_STATES
%x IN_AUTOMATON_INITIAL_STATE
%x IN_AUTOMATON_VARIABLE_NAME
%x IN_AUTOMATON_VARIABLE_DOMAIN
%x IN_STATE_TRANSITIONS
%x IN_STATE_TRANSITIONS_FINAL

/* DEFINITIONS OF REGEX */
LINE_COMM "%"[^\n]*
ML_COMM_BEGIN "/*"
ML_COMM_END "*/"
VARIABLE "variable"
VARIABLE_NAME [a-z][a-zA-Z0-9_]*
WHITESPACE [ \t\n\r]
ASSIGNMENT_OP " ::= "
ALPHABET_ELEMENT [a-zA-Z0-9]
GRAMMAR "Grammar"
AUTOMATON "FiniteAutomaton"
NAME [a-zA-Z][a-zA-Z0-9_]*
NONTERMINAL [A-Z][a-zA-Z0-9]*
TERMINAL [a-z0-9]
STATE_REGEX [q][0-9]+

%%
<*>{LINE_COMM} {/* Ignore line comments */}
<*>{ML_COMM_BEGIN} {yy_push_state(COMMENT);}
<COMMENT>[^*]* { /* Ignore multiline comments */}
<COMMENT>"*"+[^*/\n]* { /* eat up '*'s not followed by '/'s */}
<COMMENT>{ML_COMM_END} {yy_pop_state();}

{WHITESPACE} {/* Ignore whitespace */}
{VARIABLE} {
    /* initialize variable */
    domain = set<char>();
    cout << "Variabila globala:" << endl;
    BEGIN(IN_VARIABLE_NAME);
}
{NAME} {
    /* retain the name of automaton / grammar */
    currentName = yytext;
    BEGIN(IN_TYPE);
}
<IN_TYPE>{ASSIGNMENT_OP} {/* Skip the assignment operator */}
<IN_TYPE>{WHITESPACE} {/* Ignore whitespace */}
<IN_TYPE>{GRAMMAR} {
    /* initialize grammar */
    currentGrammar = Grammar();
    currentGrammar.name = currentName;
    currentGrammar.numProds = 0;
    BEGIN(IN_GRAMMAR);
}
<IN_TYPE>{AUTOMATON} {
    /* initialize automaton */
    currentAutomaton = Automaton();
    currentAutomaton.name = currentName;
    currentAutomaton.numStates = 0;
    currentAutomaton.isDeterministic = true;
    currentAutomaton.variables = vector<Variable>();
    currentAutomaton.transitions = map<string, map<string, set<string>>>();
    currentDomain.clear();
    /* add global variables to automaton */
    for(auto var : global_variables) {
        currentAutomaton.variables.push_back(var);
    }

    BEGIN(IN_AUTOMATON);
}


 /* ==================================================== GLOBAL VARIABLE PARSING ==================================================== */
<IN_VARIABLE_NAME,IN_VARIABLE_DOMAIN>{WHITESPACE} {/* Ignore whitespace */}
<IN_VARIABLE_NAME>{VARIABLE_NAME} {
    /* save the name of the variable and move to the domain */
    currentName = yytext;
    cout << "\tIdentificator: " << yytext << endl;
    BEGIN(IN_VARIABLE_DOMAIN);
}
<IN_VARIABLE_DOMAIN>{ASSIGNMENT_OP}  {/* Skip the assignment operator */}
<IN_VARIABLE_DOMAIN>[{] {/* Skip the opening bracket */}
<IN_VARIABLE_DOMAIN>{ALPHABET_ELEMENT} {
    domain.insert(yytext[0]); // Add the element to the domain
}
<IN_VARIABLE_DOMAIN>[,] {/* Skip the comma */}
<IN_VARIABLE_DOMAIN>[}] {
    cout << "\tDomeniu: {";
    for (auto it = domain.begin(); it != domain.end(); it++) {
        cout << *it;
        if (next(it) != domain.end()) {
            cout << ", ";
        }
    }
    cout << "}" << endl << endl;

    global_variables.push_back({currentName, domain, true});
}
<IN_VARIABLE_DOMAIN>[;] {
    BEGIN(INITIAL);
}

 /* ==================================================== GRAMMAR PARSING ==================================================== */
<IN_GRAMMAR>{WHITESPACE} {/* Ignore whitespace */}
<IN_GRAMMAR>"(" {/* Skip opening bracket */}
<IN_GRAMMAR>"alphabet" {
    /* move to alphabet parsing */
    BEGIN(IN_ALPHABET);
}
<IN_GRAMMAR>"nonterminals" {
    /* move to nonterminals parsing */
    BEGIN(IN_NONTERMINALS);
}
<IN_GRAMMAR>"start_symbol" {
    /* move to start symbol parsing */
    BEGIN(IN_START_SYMBOL);
}
<IN_GRAMMAR>"variable" {
    /* initialize local variable */
    currentVariable = Variable();
    currentVariable.isGlobal = false;
    BEGIN(IN_GRAMMAR_VARIABLE_NAME);
}
<IN_ALPHABET>" :: " {/* skip operator */}
<IN_ALPHABET>"{" {/* skip opening bracket */}
<IN_ALPHABET>{WHITESPACE} {/* Ignore whitespace */}
<IN_ALPHABET>{ALPHABET_ELEMENT} {
    currentGrammar.alphabet.insert(yytext[0]);
}
<IN_ALPHABET>[,] {/* Skip the comma */}
<IN_ALPHABET>"} ;" {
    /* move back to grammar parsing */
    BEGIN(IN_GRAMMAR);
}
<IN_NONTERMINALS>" :: " {/* skip operator */}
<IN_NONTERMINALS>"{" {/* skip opening bracket */}
<IN_NONTERMINALS>{WHITESPACE} {/* Ignore whitespace */}
<IN_NONTERMINALS>{NONTERMINAL} {
    currentGrammar.nonterminals.insert(yytext);
}
<IN_NONTERMINALS>[,] {/* Skip the comma */}
<IN_NONTERMINALS>"} ;" {
    /* move back to grammar parsing */
    BEGIN(IN_GRAMMAR);
}

<IN_START_SYMBOL>" :: " {/* skip operator */}
<IN_START_SYMBOL>{WHITESPACE} {/* Ignore whitespace */}
<IN_START_SYMBOL>{NONTERMINAL} {
    currentGrammar.startSymbol = yytext;
}
<IN_START_SYMBOL>";" {
    /* move back to grammar parsing */
    BEGIN(IN_GRAMMAR);
}

<IN_GRAMMAR_VARIABLE_NAME,IN_GRAMMAR_VARIABLE_DOMAIN>{WHITESPACE} {/* Ignore whitespace */}
<IN_GRAMMAR_VARIABLE_NAME>{VARIABLE_NAME} {
    currentVariable.name = yytext;
    BEGIN(IN_GRAMMAR_VARIABLE_DOMAIN);
}

<IN_GRAMMAR_VARIABLE_DOMAIN>{ASSIGNMENT_OP}  {/* Skip the assignment operator */}
<IN_GRAMMAR_VARIABLE_DOMAIN>[{] {/* Skip the opening bracket */}
<IN_GRAMMAR_VARIABLE_DOMAIN>{ALPHABET_ELEMENT} {
    currentVariable.domain.insert(yytext[0]); // Add the element to the domain
}
<IN_GRAMMAR_VARIABLE_DOMAIN>[,] {/* Skip the comma */}
<IN_GRAMMAR_VARIABLE_DOMAIN>[}] {/* Skip the closing bracket */}
<IN_GRAMMAR_VARIABLE_DOMAIN>[;] {
    currentGrammar.variables.push_back(currentVariable);
    BEGIN(IN_GRAMMAR);
}

    /* PRODUCTIONS */
<IN_GRAMMAR>{NONTERMINAL}|{TERMINAL} {
    /* start parsing the production */
    currentLHS = string(yytext);
    BEGIN(IN_PRODUCTION_LHS);
}

<IN_PRODUCTION_LHS>{NONTERMINAL}|{TERMINAL} {
    /* add to the current LHS */
    currentLHS += yytext;
}

<IN_PRODUCTION_LHS>"&" {
    /* keep the & for further tokenization */
    currentLHS += "&";
}

<IN_PRODUCTION_LHS>" ->" {
    /* move to RHS parsing */
    currentGrammar.productions.push_back({currentLHS, vector<string>()});
    currentRHS = "";
    BEGIN(IN_PRODUCTIONS);
}

<IN_PRODUCTIONS>{WHITESPACE} { /* Ignore whitespace */ }

<IN_PRODUCTIONS>"e"|{NONTERMINAL}|{TERMINAL} {
    /* add to the current RHS */
    if(currentRHS.empty()) {
        currentRHS = yytext;
    } else {
        currentRHS += yytext;
    }
}

<IN_PRODUCTIONS>"&" {
    /* keep the & for further tokenization */
    if(!currentRHS.empty()) {
        currentRHS += "&";
    }
}

<IN_PRODUCTIONS>"|" {
    /* start new production with the same LHS */
    if(!currentRHS.empty()) {
        currentGrammar.productions.back().second.push_back(currentRHS);
        currentGrammar.numProds++;
        currentRHS = "";
    }
}

<IN_PRODUCTIONS>";" {
    /* end of current production */
    if(!currentRHS.empty()) {
        currentGrammar.productions.back().second.push_back(currentRHS);
        currentGrammar.numProds++;
    }
    BEGIN(IN_GRAMMAR);
}

<IN_GRAMMAR>")"{WHITESPACE}*";;" {
    // End of grammar definition
    currentGrammar.type = determineGrammarType(currentGrammar);
    
    // Print grammar information
    cout << "Numele gramaticii: " << currentGrammar.name << endl;
    cout << "Tipul gramaticii: " << currentGrammar.type << endl;
    cout << "Numarul de reguli de productie: " << currentGrammar.numProds << endl;
    cout << "Alfabetul gramaticii: {";
    for (auto it = currentGrammar.alphabet.begin(); it != currentGrammar.alphabet.end(); ++it) {
        cout << *it;
        if (next(it) != currentGrammar.alphabet.end()) cout << ", ";
    }
    cout << "}" << endl;
    // Print variables
    for (auto var : currentGrammar.variables) {
        cout << "Variabila locala:" << endl;
        cout << "\tIdentificator: " << var.name << endl;
        cout << "\tDomeniu: {";
        for (auto it = var.domain.begin(); it != var.domain.end(); it++) {
            cout << *it;
            if (next(it) != var.domain.end()) {
                cout << ", ";
            }
        }
        cout << "}" << endl;
    }

    cout << endl;
    
    BEGIN(INITIAL);
}
    /* ==================================================== AUTOMATON PARSING ==================================================== */
<IN_AUTOMATON>{WHITESPACE} {/* Ignore whitespace */}
<IN_AUTOMATON>"(" {/* Skip opening bracket */}
<IN_AUTOMATON>"alphabet" {
    /* move to alphabet parsing */
    BEGIN(IN_AUTOMATON_ALPHABET);
}
<IN_AUTOMATON>"states" {
    /* move to states parsing */
    BEGIN(IN_AUTOMATON_STATES);
}
<IN_AUTOMATON>"final_states" {
    /* move to final states parsing */
    BEGIN(IN_AUTOMATON_FINAL_STATES);
}
<IN_AUTOMATON>"initial_state" {
    /* move to initial state parsing */
    BEGIN(IN_AUTOMATON_INITIAL_STATE);
}
<IN_AUTOMATON>"variable" {
    /* initialize local variable */
    currentVariable = Variable();
    currentVariable.isGlobal = false;
    BEGIN(IN_AUTOMATON_VARIABLE_NAME);
}
<IN_AUTOMATON>{STATE_REGEX} {
    /* initialize state */
    currentAutomaton.transitions[yytext] = map<string, set<string>>();
    currentState = yytext;
    /* move to state transitions parsing */
    BEGIN(IN_STATE_TRANSITIONS);
}

<IN_AUTOMATON_ALPHABET>" :: " {/* skip operator */}
<IN_AUTOMATON_ALPHABET>"{" {/* skip opening bracket */}
<IN_AUTOMATON_ALPHABET>{WHITESPACE} {/* Ignore whitespace */}
<IN_AUTOMATON_ALPHABET>{ALPHABET_ELEMENT} {
    currentAutomaton.alphabet.insert(yytext[0]);
}
<IN_AUTOMATON_ALPHABET>[,] {/* Skip the comma */}
<IN_AUTOMATON_ALPHABET>"} ;" {
    /* move back to automaton parsing */
    BEGIN(IN_AUTOMATON);
}

<IN_AUTOMATON_STATES>" :: " {/* skip operator */}
<IN_AUTOMATON_STATES>"{" {/* skip opening bracket */}
<IN_AUTOMATON_STATES>{WHITESPACE} {/* Ignore whitespace */}
<IN_AUTOMATON_STATES>{STATE_REGEX} {
    currentAutomaton.states.insert(yytext);
    currentAutomaton.numStates++;
}
<IN_AUTOMATON_STATES>[,] {/* Skip the comma */}
<IN_AUTOMATON_STATES>"} ;" {
    /* move back to automaton parsing */
    BEGIN(IN_AUTOMATON);
}

<IN_AUTOMATON_FINAL_STATES>" :: " {/* skip operator */}
<IN_AUTOMATON_FINAL_STATES>"{" {/* skip opening bracket */}
<IN_AUTOMATON_FINAL_STATES>{WHITESPACE} {/* Ignore whitespace */}
<IN_AUTOMATON_FINAL_STATES>{STATE_REGEX} {
    /* add final state */
    currentAutomaton.finalStates.insert(yytext);
}
<IN_AUTOMATON_FINAL_STATES>[,] {/* Skip the comma */}
<IN_AUTOMATON_FINAL_STATES>"} ;" {
    /* move back to automaton parsing */
    BEGIN(IN_AUTOMATON);
}

<IN_AUTOMATON_INITIAL_STATE>" :: " {/* skip operator */}
<IN_AUTOMATON_INITIAL_STATE>{WHITESPACE} {/* Ignore whitespace */}
<IN_AUTOMATON_INITIAL_STATE>{STATE_REGEX} {
    /* set initial state */
    currentAutomaton.initialState = yytext;
}
<IN_AUTOMATON_INITIAL_STATE>";" {
    /* move back to automaton parsing */
    BEGIN(IN_AUTOMATON);
}

<IN_AUTOMATON_VARIABLE_NAME,IN_AUTOMATON_VARIABLE_DOMAIN>{WHITESPACE} {/* Ignore whitespace */}
<IN_AUTOMATON_VARIABLE_NAME>{VARIABLE_NAME} {
    /* save the name of the variable and move to the domain */
    currentVariable.name = yytext;
    BEGIN(IN_AUTOMATON_VARIABLE_DOMAIN);
}

<IN_AUTOMATON_VARIABLE_DOMAIN>{ASSIGNMENT_OP}  {/* Skip the assignment operator */}
<IN_AUTOMATON_VARIABLE_DOMAIN>[{] {/* Skip the opening bracket */}
<IN_AUTOMATON_VARIABLE_DOMAIN>{ALPHABET_ELEMENT} {
    currentVariable.domain.insert(yytext[0]); // Add the element to the domain
}
<IN_AUTOMATON_VARIABLE_DOMAIN>[,] {/* Skip the comma */}
<IN_AUTOMATON_VARIABLE_DOMAIN>[}] {/* Skip the closing bracket */}
<IN_AUTOMATON_VARIABLE_DOMAIN>[;] {
    /* add variable to automaton */
    currentAutomaton.variables.push_back(currentVariable);
    BEGIN(IN_AUTOMATON);
}

<IN_STATE_TRANSITIONS>" -> " {/* Skip the operator */}
<IN_STATE_TRANSITIONS>"(" {/* Skip the opening bracket */}
<IN_STATE_TRANSITIONS>{WHITESPACE} {/* Ignore whitespace */}
<IN_STATE_TRANSITIONS>{ALPHABET_ELEMENT}|{VARIABLE_NAME} {
    string symbol = yytext;
    isVariable = false;
    currentDomain.clear();

    // check if it is a variable
    for(auto var : currentAutomaton.variables) {
        if(var.name == symbol) {
            currentDomain = var.domain;
            isVariable = true;
            break;
        }
    }
    
    if (!isVariable) {
        // Add the symbol to the domain of the transition
        currentDomain.insert(symbol[0]);
    }

    BEGIN(IN_STATE_TRANSITIONS_FINAL);
}

<IN_STATE_TRANSITIONS_FINAL>"->" {/* Skip the operator */}
<IN_STATE_TRANSITIONS_FINAL>{STATE_REGEX} {
    string nextState = yytext;
    for(auto c : currentDomain) {
        string symbol(1, c);
        // check if c is "e"
        if(c == 'e') {
            currentAutomaton.isDeterministic = false;
        }

        // Only add transitions for symbols that are in the automaton's alphabet or 'e'
        if(currentAutomaton.alphabet.count(c) > 0 || c == 'e') {
            currentAutomaton.transitions[currentState][symbol].insert(nextState);
        }
        // If there is more than one transition for a symbol, the automaton is non-deterministic
        if(currentAutomaton.transitions[currentState][symbol].size() > 1) {
            currentAutomaton.isDeterministic = false;
        }

    }
   
}
<IN_STATE_TRANSITIONS_FINAL>" ;" {
    /* move back to state transitions parsing */
    currentDomain.clear();
    BEGIN(IN_STATE_TRANSITIONS);
}
<IN_STATE_TRANSITIONS_FINAL>{WHITESPACE} {/* Ignore whitespace */}
<IN_STATE_TRANSITIONS>") ;" {
    /* move back to automaton parsing */
    BEGIN(IN_AUTOMATON);
}

<IN_AUTOMATON>") ;;" {
    cout << "Numele automatului: " << currentAutomaton.name << endl;
    cout << "Tipul automatului: ";
    if(currentAutomaton.isDeterministic) {
        cout << "Automat finit determinist" << endl;
    }
    else {
        cout << "Automat finit nedeterminist" << endl;
    }
    cout << "Alfabetul de intrare: {";
    for(auto it = currentAutomaton.alphabet.begin(); it != currentAutomaton.alphabet.end(); it++) {
        cout << *it;
        if(next(it) != currentAutomaton.alphabet.end()) {
            cout << ", ";
        }
    }
    cout << "}" << endl;
    cout << "Numarul de stari: " << currentAutomaton.numStates << endl;
    cout << "Starea initiala: " << currentAutomaton.initialState << endl;
    cout << "Starile finale: {";
    for(auto it = currentAutomaton.finalStates.begin(); it != currentAutomaton.finalStates.end(); it++) {
        cout << *it;
        if(next(it) != currentAutomaton.finalStates.end()) {
            cout << ", ";
        }
    }
    cout << "}" << endl;
    cout << "Functia de tranzitie:" << endl;
    for(auto it = currentAutomaton.transitions.begin(); it != currentAutomaton.transitions.end(); it++) {
        for(auto it2 = it->second.begin(); it2 != it->second.end(); it2++) {
            for(auto it3 = it2->second.begin(); it3 != it2->second.end(); it3++) {
                cout << "\tm(" << it->first << ", " << it2->first << ") = " << *it3 << endl;
            }

        }
    
    }
    for(auto var : currentAutomaton.variables) {
        if(var.isGlobal == true)
            continue;

        cout << "Variabila locala:" << endl;
        cout << "\tIdentificator: " << var.name << endl;
        cout << "\tDomeniu: {";
        for(auto it = var.domain.begin(); it != var.domain.end(); it++) {
            cout << *it;
            if(next(it) != var.domain.end()) {
                cout << ", ";
            }
        }
        cout << "}" << endl;
    }

    currentDomain.clear();
    cout << endl;

    BEGIN(INITIAL);
}
%%

int main(int argc, char* argv[]) {
    if(argc != 2) {
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
    }

    FILE *fin = fopen(argv[1], "r");
    if (!fin) {
        cerr << "Could not open input file" << endl;
        return 1;
    }

    // Set the input file
    yyin = fin;
    yylex();

    fclose(fin);
    return 0;
}