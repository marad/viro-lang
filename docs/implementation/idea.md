Co jeśli chciałbym, żeby wszystkie wartości w Viro to były bezpośrednie wartości w Lua?

Dane takie jak konkretny typ mogłyby być w metatablicach, ale one są wspierane tylko dla tablic.

Problemem byłyby takie typy jak `file!` bo to jest w zasadzie `string!` tylko inaczej traktowany, a bez dodatkowej informacji nie ma go jak odróżnić.