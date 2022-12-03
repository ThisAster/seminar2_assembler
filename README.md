*TITLE: Семинар 2: вызов фунцкий, использование стека, конечные автоматы


* Tема занятия
  :PROPERTIES:
  :UNNUMBERED: t
  :END:

  - На этом занятии мы реализуем несколько кусочков из первой лабораторной работы и пронаблюдаем за вызовом функций.
  - Узнаем про использование стека для организации вызова процедур и хранения локальных переменных.
  - В первом приближении изучим используемое соглашение вызова и научимся правильно вызывать функции.
  - Познакомимся с понятием конечного автомата и связанной ним терминологией.
  - Увидим связь между рерулярными выражениями и конечными автоматами.
  - Научимся кодировать конечные автоматы на языке ассемблера.

Перед началом семинара следует ознакомиться с секциями 2.3-2.6 и 7.1 книги "Low-level programming"
 
* Определение функций

  Вспомним привычный уже код программы =Hello, world!=:

#BEGIN_SRC asm
; hello.asm 
section .data
message: db  'hello, world!', 10

section .text
global _start

_start:
    mov  rax, 1              ; 'write' syscall number
    mov  rdi, 1              ; stdout descriptor
    mov  rsi, message        ; string address
    mov  rdx, 14             ; string length in bytes
    syscall

    mov  rax, 60             ; 'exit' syscall number
    xor  rdi, rdi            ; error code
    syscall
  #END_SRC

Она завершается системным вызовом =exit=, который выходит из программы. 

#+BEGIN_SRC asm
    mov  rax, 60             ; 'exit' syscall number
    xor  rdi, rdi
    syscall
#+END_SRC

Было бы удобнее именовать эту последовательность инструкций и вызвать её по имени. Так мы, взглянув на программу, сразу поймём, чего хотел программист.

Кроме того, это полезно, мы выходим из программы более, чем в одном месте --- не нужно переписывать эти три инструкции.

#BEGIN_SRC asm
; hello.asm 
section .data
message: db  'hello, world!', 10

section .text
global _start

exit:                        ; Это метка начала функции exit
    mov  rax, 60             ; Это функция exit
    xor  rdi, rdi            ; Это функция exit
    syscall                  ; Это функция exit

_start:
    mov  rax, 1
    mov  rdi, 1
    mov  rsi, message  
    mov  rdx, 14         
    syscall
    call exit                ; это вызов функции exit
#+END_SRC

Итак, чтобы определить функцию, нужно создать для неё метку (в данном случае =exit=) и выделить её код отдельно по этой метке.

Чтобы при выполнении программы обратиться к ней и вызвать её используется инструкция =call=, в которую передаётся адрес начала функции.

*Терминологическое* Иногда функции на уровне ассемблера называют подпрограммами (subroutine) чтобы отличать их от функций на языках высокого уровня.



* Возврат из функций
Вообще от подпрограмм требуется поддержка двух действий:

- нам необходимо иметь возможность вызывать их отовсюду;
- подпрограммы должны иметь возможность вернуться в место вызова, чтобы программа продолжила работу.

Чтобы завершить выполнение функции и вернуться в место, откуда она была вызвана, используется инструкция =ret=.

Напишем другую функцию, которая при вызове выводит =Hello, world!= и с её помощью выведем =Hello, world!= дважды.

#+BEGIN_SRC asm
; hello.asm 
section .data
message: db  'hello, world!', 10

section .text
global _start

exit:                        ; Это метка начала функции exit
    mov  rax, 60             ; Это функция exit
    xor  rdi, rdi
    syscall

print_string:                ; Это метка начала функции print_string
    mov  rax, 1              ; Это функция print_string
    mov  rdi, 1
    mov  rsi, message
    mov  rdx, 14
    syscall
    ret                      ; Выход из функции print_string

_start:
    call print_string        ; Вызов функции print_string
    call print_string        ; Вызов функции print_string
    call exit                ; Вызов функции exit
#+END_SRC


*Вопрос* Выполните эту программу по шагам в =gdb= и проследите за указателем на стек (регистром =rsp=). Как на него влияют инструкции =call= и =ret=?

*Вопрос*  Обратитесь к Intel software developer manual и прочитайте странички, соответствующие инструкциям =call= и =ret=. Опишите действие этих инструкций на память и регистры.

*Вопрос* Как будет изменяться состояние стека если функция =f= вызывает функцию =g=? Напишите программу, где есть такие функции и вызовы; выполните её по шагам в gdb и проследите за указателем на стек (регистром =rsp=).

*Вопрос* Почему мы не написали инструкцию =ret= в конце функции =exit=?

* Функции с аргументами

Функция =print_string= всегда забирает данные с адреса =message=, что существенно ограничивает её полезность.
Чтобы дать возможность каждый раз при запуске указывать, на каких данных функция работает (в данном случае, какую строку выводить) мы параметризуем функции, добавляя /аргументы/. Каждый аргумент это кусок данных, который нужен функции для работы, например, адрес начала строки для вывода.

Функции могут иметь множество аргументов. Первые шесть они получают через регистры.

*Вопрос* Какие регистры для этого используются? Ищите ответ в секции 2.4 "Low-level programming".

Например, мы хотели бы вызвать функцию =sum=, которая на псевдокоде выглядит так:

#BEGIN_SRC c
// это псевдокод
int sum(int a, int b) {
  return a + b;
}

// при вызове мы хотим поместить результат в rcx
rcx <- sum( 42, 44 )
#+END_SRC

Вот реализация функции =sum= и её вызов:

#BEGIN_SRC asm
; rdi = a, rsi = b
sum: 
      mov  rax, rdi
      add  rax, rsi
      ret

...
mov  rdi, 42
mov  rsi, 44
call sum
mov  rcx, rax
#END_SRC

Функция получает аргументы =a= и =b= через первые два регистра, используемые для передачи аргументов: =rdi= и =rsi=.
При необходимости, следующие четыре аргумента перевались бы через регистры =rdx=, =rcx=, =r8= и =r9= (смотри секцию 2.4 книги "Low-level programming").
При этом правильность вызова никак не контролируется. Рассмотрим следующий код:

#BEGIN_SRC asm
; rdi = a, rsi = b
sum: 
      mov  rax, rdi
      add  rax, rsi
      ret

...
mov  rdi, 42   
call sum         ; Второй аргумент всё равно возьмётся из rsi
mov  rcx, rax     ; Скорее всего там "мусорное" значение
#+END_SRC 

Результат вызва функции =sum= в данном случае будет зависиить от выполненых ранее команд и финального состояния регистра =rsi=.

*Вопрос*  Есть ли разница между этими двумя вызовами функции =f= с двумя аргументами?

#BEGIN_SRC asm
  mov  rdi,10
  mov  rsi, 30
  call f

  mov  rsi, 30
  mov  rdi,10
  call f
#END_SRC

*Вопрос* Сколько аргументов нужно передать рассмотренной ранее функции =print_string=, чтобы она могла вывести любую строку с помощью системного вызова =write=? Хватит ли одного? 

*Задание 1* Выделите из следующего кода (взято со стр. 22 книги "Low-level programming") функцию =print_hex=, которая примет аргумент в правильном регистре (не =rax=) и выведет его на экран. Выведите с её помощью любые три числа.

#BEGIN_SRC asm
; print_hex.asm
section .data
codes:
    db      '0123456789ABCDEF'

section .text
global _start
_start:
    ; number 1122... in hexadecimal format
    mov  rax, 0x1122334455667788

    mov  rdi, 1
    mov  rdx, 1
    mov  rcx, 64
	; Each 4 bits should be output as one hexadecimal digit
	; Use shift and bitwise AND to isolate them
	; the result is the offset in 'codes' array
.loop:
    push rax
    sub  rcx, 4
	; cl is a register, smallest part of rcx
	; rax -- eax -- ax -- ah + al
	; rcx -- ecx -- cx -- ch + cl
    sar  rax, cl
    and  rax, 0xf

    lea  rsi, [codes + rax]
    mov  rax, 1

    ; syscall leaves rcx and r11 changed
    push rcx
    syscall
    pop  rcx

    pop rax
	; test can be used for the fastest 'is it a zero?' check
	; see docs for 'test' command
    test rcx, rcx
    jnz .loop

    mov  rax, 60            ; invoke 'exit' system call
    xor  rdi, rdi
    syscall

#END_SRC

* Возврат значений из функций

Зачастую цель написания функции --- в подсчёте данных, которые потом нужно передать в основную программу, которая функцию и вызвала. По соглашению, после завершения выполнения функции пара регистров =rax= (основное значение) и =rdx= хранят значение, подсчитанное функцией. Оно также называется /возвращаемое значение/. Перечитайте про это в 
секции 2.4 из книги "Low-level programming".

*Задание 2* Прочитате секцию 2.5.2 из книги "Low-level programming". Перепишите следующую программу так, чтобы функция =print_string= принимала нуль-терминированную строку в единственном аргументе строки. С помощью [[./test_string.py][тестировщика]] протестируйте работу функций =string_length= и =print_string=.

#BEGIN_SRC asm
; print_string.asm 
section .data
message: db  'hello, world!', 10

section .text
global _start

exit:
    mov  rax, 60
    xor  rdi, rdi          
    syscall

string_length:
  mov rax, 0
    .loop:
      xor rax, rax
    .count:
      cmp byte [rdi+rax], 0
      je .end
      inc rax
      jmp .count
    .end:
      ret

print_string:
    mov  rdx, rsi
    mov  rsi, rdi
    mov  rax, 1
    mov  rdi, 1
    syscall
    ret

_start:
    mov  rdi, message
    mov  rsi, 14  
    call print_string
    call exit                    ; это вызов функции exit
#+END_SRC





* Соглашение вызова
В /секции 2.4 из книги "Low-level programming" говорилось про /соглашение вызова/. Это набор правил вызова функций; соблюдение этих правил гарантирует возможность свободно переписывать функции и подменять их реализации.

Если не соблюдать соглашение вызова, вызов функций станет ненадёжным: что-то сломается или сейчас, или в будущем, после подмены функции на новую реализацию.

По соглашению о вызовах следующие регистры являются /callee-saved/: =rbx=, =rbp=, =rsp= и с =r12= по =r15=. Все остальные регистры являются /caller-saved/.


*Вопрос* Что такое /callee-saved/ и /caller-saved/ регистры? В чём разница между их использованием при вызове функций?

*Вопрос* Почему не сделать все регистры /callee-saved/?


*Вопрос* Будет ли работать этот код на ассемблере? Корректен ли он с точки зрения соглашений?

#BEGIN_SRC asm
; rdi = адрес строки
string_length:
    xor  rax, rax
    .counter:
        cmp  byte [rdi+rax], 0
        je   .end
        inc  rax
        jmp  .counter
    .end:
        ret

; rdi = адрес строки
print_string:
    call string_length
    mov  rdx, rax
    mov  rax, 1
    mov  rsi, rdi
    mov  rdi, 1
    syscall           ; вызов write
    ret
#END_SRC

*Вопрос* Будет ли работать этот код на ассемблере? Корректен ли он с точки зрения соглашений?

#+BEGIN_SRC asm
; rdi = адрес строки
string_length:
    mov  rax, rdi
    .counter:
        cmp  byte [rdi], 0
        je   .end
        inc  rdi
        jmp  .counter
    .end:
    sub  rdi, rax
    mov  rax, rdi
    ret
; rdi = адрес строки
print_string:
    call string_length
    mov  rdx, rax
    mov  rax, 1
    mov  rsi, rdi
    mov  rdi, 1
    syscall           ; вызов write
    ret
#END_SRC




* Использование стека для локальных переменных

Как вы поняли, при вызове функции инструкция =call= кладёт на вершину стека адрес возврата.
Если после этого уменьшить указатель на вершину стека =rsp= так, чтобы между ним и адресом возврата можно было уместить нужные нам для работы временные данные, мы говорим, что мы /выделили память в стеке/.


*Вопрос* Есть ли разница между следующими способами выделения памяти?

#BEGIN_SRC asm
; Первый способ
sub  rsp, 24

; Второй способ
push 0
push 0
push 0
#+END_SRC


*Задание 3* Напишите функцию, которая выделит место под три локальные переменные, запишет туда =aa=, =bb= и =ff= и выведет их на экран. Затем она должна корректно завершиться. Протестируйте её. Для вывода на экран используйте уже написанную в начале семинара =print_hex=.









* Введение в конечные автоматы
  
  Конечный автомат (Finite State Machine) это:

  - Набор событий (/входные символы/).
  - Набор реакций (/выходные символы/).
  - Набор состояний, из них выбираем одно начальное, одно или более конечных.
  - Правила вида: "если мы в состоянии *A* и произошло событие *I*, демонстрировать реакцию *O* и перейти в состояние *B*".

    Общий вид правила:
  [[./img/fsm-io.svg]]


  - Реакцию можно не демонстрировать.
  - В какое состояние придём, такой и результат работы.

    Сначала посмотрим на автоматы без реакций, т.е. набор реакций пустой и все переходы помечены только входными символами.

** Пример. Чётное количество единиц
   События: считывание очередного символа из строчки.

   [[./img/fsm-2.svg]]


   Автомат можно мысленно запустить и дать ему на вход последовательность событий.
   Затем, стартовав из начального состояния, пройтись по цепочке переходов (одно
   событие --- один переход).

   *Вопрос* по какой цепочке переходов пройдёт этот автомат на входной строке 01001? Считаем, что никаких реакций нет.

** Пример. Разбираем число со знаком

   [[./img/fsm-1.svg]]

   *Вопрос* а если число без знака? Нарисуйте автомат для распознавания таких чисел.

** Пример. Пять состояний процесса
   
   [[./img/fsm-processes.svg]]

   *Вопрос* Расскажите, о чём эта диаграмма? Верна ли она для всех операционных систем?

** Другие use-cases

   - Управление роботами, машинами.
     - События = показания сенсоров.
     - Реакции = действия.
   - Сетевые протоколы.
     - События = приём пакетов разного типа.
     - Реакции = ответы.

* Чем автоматы непривычны

  - Состояние компьютера --- значения всех регистров и ячеек памяти.
  - Состояние автомата  --- "кружочек", одно из фиксированного набора.
  - У автомата нет памяти, никакой.

  Когда в алгоритме действия и условия глобальны, автоматы удобны для его описания.

* Как закодировать автомат на ассемблере

  Прочитайте на страницах 103--105 книги "Low-level programming" о том, как закодировать на ассемблере конечный автомат.

  *Вопрос* Закодируйте автомат, проверяющий, является ли строчка числом (т.е. что она удовлетворяет регулярному выражению =\s*[0-9]+\s*=  ).

* Автоматы и регулярные выражения
  
  Прочитайте на страницах 106--108 книги "Low-level programming" о  связи регулярных выражений и конечных автоматов.

  *Вопрос* Нарисуйте автомат, соответствующий регулярному выражению =[+-]?[0-9]+=.

  На автоматах легко продемонстрировать понятия /недетерминизма/, /неопределённости/ и /полноты/.

* Что такое недетерминизм?

  Поведение --- последовательность переходов по состояниям.

  - Несколько возможных переходов по одинаковому событию.
    - Мы в состоянии *A*, что если на входе 3?
  - Не одно поведение, а *множество равноправных*.

  [[./img/fsm-nondeterm.svg]]



  *Связано с*: неопределённым порядком вычислений в C, слабой моделью памяти.

** Недетерминизм в C

   #BEGIN_SRC c
     int f() { print("f"); return 1; }
     int g() { print("g"); return 1; }

     ...
     f() + g();
   #END_SRC

   [[./img/fsm-nondeterm-c.svg]]


   =f() + g();= - =1 + g();= - =1 + 1= - =2= 

   =f() + g();= - =f() + 1;= - =1 + 1= - =2= 


* Что такое неопределённость?

  - Мы в состоянии *A*, что будет если на вход придёт 1?
  - Нет поведения.

  [[./img/fsm-nondeterm.svg]]

  При реализации системы в неописанных случаях поведение &laquo;как получится&raquo;.

  *Связано с*: неопределённым поведением в C; используется чтобы
  компилятор вставлял меньше проверок.

  ---

* Что такое полнота?

  - Полный автомат = не может быть неопределённого поведения.
  - Из каждого состояния для каждого возможного события есть переход.
  - Неполный можно достроить до полного добавив состояние.

Пример неполного автомата:

   [[./img/fsm-1.svg]]

Достроим его до полного:

   [[./img/fsm-3.svg]]

*Кодировать на ассемблере имеет смысл только полные автоматы*.

Автоматы легко анализировать, на их основе легко писать программы, и их можно полностью проанализировать, в отличие от программ на привычных языках программирования.

* Разбор чисел

  Задача, которая ставится в функции =read_uint= из первой лабораторной работы, немного сложнее, чем просто ответить на вопрос "да" или "нет" (прийти в одно из конечных состояний).
  Нужно также подсчитать число, взяв его десятичные цифры из строки.

  Важно, что все действия глобальны (с регистрами) и происходят в момент переходов. Поэтому мы можем воспринимать их как "реакции" системы на входные символы (буквы/символы из входной строки). 

  *Задание 4* Нарисуйте автомат для функции =read_uint= на основе заготовки из одного из предыдущих пунктов; снабдите его переходы также действиями над регистрами, в результате которых в =rax= окажется разобранное из строчки число, а в =rdx= количество символов в нём. Затем *закодируйте этот автомат* на ассемблере и проверьте с помощью [[https://gitlab.se.ifmo.ru/programming-languages/cse-programming-languages-fall-2022/main/-/blob/master/seminar-2/test_uint.py][теста]].
  
  *Вопрос* внимательно посмотрите на все функции, которые необходимо реализовать в первой лабораторной. Для каких из них удобно сначала нарисовать автомат, а затем закодировать его на ассемблере?

  При кодировании конечных автоматов на языке ассемблера каждому состоянию автомата соответствует метка (label).
  Для кодирования переходов между состояниями будут использоваться команды безусловного или условного перехода.
  Чаще всего вы будете использовать следующие команды:

  - =jmp= команда безусловного перехода по заданой метке.
  - =cmp= команда сравнения. Устанавливает значение флагов в соответствии с результатом операции.
  - =je= (jump if equal) или =jz= (jump if zero) выполняет переход по заданной метке в случае если флаг =zf= равен 1 (например когда в результате выполнения операции =cmp= значения оказались равны).
  - =jne= (jump if not equal) или =jnz= (jump if not zero) выполняет переход по заданной метке в случае если флаг =zf= равен 0 (например когда в результате выполнения операции =cmp= значения оказались *не* равны).

  - =jb= (jump if below), =jnae= (jump if not above or equal) или =jc= (jump if carry) выполняет переход если флаг =cf= равен 1 (например когда первый операнд в =cmp= был меньше второго при сравнении беззнаковых чисел).
  - =jnb= (jump if not below), =jae= (jump if above or equal) или =jnc= (jump if not carry) выполняет переход если флаг =cf= равен 0 (например когда первый операнд в =cmp= был больше либо равен второму при сравнении беззнаковых чисел).
  - =jbe= (jump if below or equal) или =jna= (jump if not above) выполняет переход если флаг =cf= равен 1 или =zf= равен 1 (например когда первый операнд в =cmp= был меньше либо равен второму при сравнении беззнаковых чисел).
  - =jnbe= (jump if not below or equal) илил =ja= (jump if above) выполняет переход если флаги =cf= и =zf= равны 0 (например когда первый операнд в =cmp= был больше второго при сравнении беззнаковых чисел).

  - =jl= (jump if less) или =jnge= (jump if not greater or equal) выполняет переход если значение флага =sf= *не* равно значению флага =of= (например когда первый операнд в =cmp= был меньше второго при сравнении знаковых чисел).
  - =jnl= (jump if not less) или =jge= (jump if greater or equal) выполняет переход если значение флага =sf= равно значению флага =of= (например когда первый операнд в =cmp= был больше либо равен второму при сравнении знаковых чисел).
  - =jle= (jump if less or equal) или =jng= (jump if not greater) выполняет переход если флаг значение флага =sf= *не* равно значению флага =of= или =zf= равен 1 (например когда первый операнд в =cmp= был меньше либо равен второму при сравнении знаковых чисел).
  - =jnle= (jump if not less or equal) илил =jg= (jump if greater) выполняет переход если значение флага =sf= равно значению флага =of= и =zf= равны 0 (например когда первый операнд в =cmp= был больше второго при сравнении знаковых чисел).
