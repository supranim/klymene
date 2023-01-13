# Klymene - Build delightful Command Line Interfaces.
# 
#   (c) 2022 George Lemon | MIT license
#       Made by Humans from OpenPeep
#       https://github.com/openpeep/klymene

# References
# https://github.com/nim-lang/nimble/blob/master/nimble.bash-completion
# https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion-Builtins.html#Programmable-Completion-Builtins
# https://devhints.io/bash#functions

import std/[tables]
from std/strutils import indent, join, `%`


type
  Flags = enum
    CompOptionFlag
      # The comp-option controls several aspects of the compspec’s
      # behavior beyond the simple generation of completions.
      # ``CompOption`` may be one of ``CompOptionFlags``
    ActionFlag
      # The action may be one of the following to generate
      # a list of possible completions under ``ActionFlags``
    CommandFlag
      # command is executed in a subshell environment,
      # and its output is used as the possible completions.
    FunctionFlag
      # The shell function function is executed in the current
      # shell environment. When it is executed, $1 is the name
      # of the command whose arguments are being completed,
      # $2 is the word being completed, and $3 is the word
      # preceding the word being completed, as described above
      # (see Programmable Completion). When it finishes,
      # the possible completions are retrieved from the value
      # of the COMPREPLY array variable.
    GlobPatFlag
      # The filename expansion pattern globpat is expanded to
      # generate the possible completions.
    PrefixFlag = "-P"
      # Added at the beginning of each possible completion
      # after all other options have been applied.
    SuffixFlag = "-S"
      # Appended to each possible completion after all
      # other options have been applied.
    WordlistFlag = "-W"
      # The ``WordlistFlag`` is split using the characters in the IFS
      # special variable as delimiters, and each resultant
      # word is expanded. The possible completions are the
      # members of the resultant list which match the word
      # being completed. Flag ``-W``
    FilterPatFlag
      # pattern as used for filename expansion.
      # It is applied to the list of possible completions
      # generated by the preceding options and arguments,
      # and each completion matching filterpat is removed
      # from the list. A leading ‘!’ in filterpat negates
      # the pattern; in this case, any completion not matching
      # filterpat is removed.

  CompOptionFlags = enum
    BashDefault
      # Perform the rest of the default Bash completions
      # if the compspec generates no matches.
    Default
      # Use Readline’s default filename completion if
      # the compspec generates no matches.
    Dirnames
      # Perform directory name completion if the
      # compspec generates no matches.
    Filenames
      # Tell Readline that the compspec generates filenames,
      # so it can perform any filename-specific processing
      # (like adding a slash to directory names, quoting special
      # characters, or suppressing trailing spaces). This option is
      # intended to be used with shell functions specified with -F.
    NoQuote
      # Tell Readline not to quote the completed words if
      # they are filenames (quoting filenames is the default).
    NoSort
      # Tell Readline not to sort the list of possible
      # completions alphabetically.
    NoSpace
      # Tell Readline not to append a space (the default)
      # to words completed at the end of the line.
    PlusDirs
      # After any matches defined by the compspec are generated,
      # directory name completion is attempted and any matches
      # are added to the results of the other actions.

  ActionFlags* = enum
    Alias
      # Alias names. May also be specified as -a.
    ArrayVar
      # Array variable names.
    Binding
      # Readline key binding names (see Bindable Readline Commands).
    Builtin
      # Names of shell builtin commands. May also be specified as -b.
    Command = "-c"
      # Command names. May also be specified as -c.
    Directory = "-d"
      # Directory names. May also be specified as -d.
    Disabled
      # Names of disabled shell builtins.
    Enabled
      # Names of enabled shell builtins.
    Export
      # Names of exported shell variables. May also be specified as -e.
    File
      # File names. May also be specified as -f.
    Function
      # Names of shell functions.
    Group
      # Group names. May also be specified as -g.
    Helptopic
      # Help topics as accepted by the help builtin 
      # (see Bash Builtins).
    Hostname
      # Hostnames, as taken from the file specified
      # by the HOSTFILE shell variable (see Bash Variables).
    Job
      # Job names, if job control is active.
      # May also be specified as -j.
    Keyword
      # Shell reserved words. May also be specified as -k.
    Running
      # Names of running jobs, if job control is active.
    Service
      # Service names. May also be specified as -s.
    SetOpt
      # Valid arguments for the -o option to the set
      # builtin (see The Set Builtin).
    ShOpt
      # Shell option names as accepted by the shopt builtin
      # (see Bash Builtins).
    Signal
      # Signal names.
    Stopped
      # Names of stopped jobs, if job control is active.
    User
      # User names. May also be specified as -u.
    Variable
      # Names of all shell variables. May also be specified as -v.

  CompletionType = enum
    Static, Dynamic

  Completion = ref object
    words: seq[string]
    cursor_words: int
      ## an index of the ``words`` field pointing to the
      ## word the current cursor is at. In other words,
      ## the index of the word the cursor was when
      ## the tab key was pressed
    case flagType: Flags
    of CompOptionFlag:
      comp_option_flag: CompOptionFlags
    of ActionFlag:
      action_flag: ActionFlags
    else: discard

# Bash Variables
# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#Bash-Variables

  AutoCompletion = object
    appName: string
    completion: Completion
    output: string

proc newAutoCompletion*(appName: string): ref AutoCompletion =
  ## Generate a BASH auto completion script based on given commands
  result = new AutoCompletion
  result.appName = appName

proc action*[A: ref AutoCompletion](autoComp: A, actionFlag: ActionFlags) =
  ## Set an action flag to current AutoCompletion
  autoComp.completion = Completion(flagType: ActionFlag)
  autoComp.completion.action_flag = actionFlag

proc registerCommands*[A: ref AutoCompletion](autoComp: A, words: seq[string]) =
  autoComp.completion.words = words

proc line[A: ref AutoCompletion](autoComp: A, lineStr: string, isize = 0, nlBefore = false, nlAfter = true) =
  if nlBefore: add autoComp.output, "\n"
  add autoComp.output, indent(lineStr, isize)
  if nlAfter: add autoComp.output, "\n"

proc openFn(appName: string): string = 
  result = "__$1_autoCompleteKlymeneApp() {\n" % [appName]

proc closeFn(): string = "\n}\n"

proc source*[A: ref AutoCompletion](autoComp: A): string =
  ## Output the AutoComplete BASH script
  add autoComp.output, "#/usr/bin/env bash\n"
  autoComp.line openFn(autoComp.appName), nlAfter = false
  autoComp.line("local cur=${COMP_WORDS[COMP_CWORD]}", 4)
  autoComp.line("local prev=${COMP_WORDS[COMP_CWORD-1]}", 4)
  autoComp.line("COMPREPLY=()", 4)
  autoComp.line closeFn(), nlAfter = false

  case autoComp.completion.flagType:
  of WordlistFlag:
    add autoComp.output, indent($(autoComp.completion.action_flag), 1)
    add autoComp.output, indent("\"" & join(autoComp.completion.words, " ") & "\"", 1)
    add autoComp.output, indent(autoComp.appName, 1)
  else: discard

  result = autoComp.output
