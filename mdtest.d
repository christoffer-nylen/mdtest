import std.getopt, std.range, std.stdio, std.ascii, std.process, std.string;

import std.regex : ctRegex, replaceAll;

bool verbose = false;
bool showHeaders = false;
bool useSpace = false;
bool useBold = false;
bool showAllMdLines = false;
string mdFile = "none";
bool runDisabled = false;
bool breakOnFailure = false;

const string ANSI_COLOR_RED = "\x1b[31m";
const string ANSI_COLOR_GREEN = "\x1b[32m";
const string ANSI_BOLD = "\x1b[1m";
const string ANSI_COLOR_RESET = "\x1b[0m";

// An allowed environment variable name according to POSIX: "a word consisting
// solely of underscores, digits, and alphabetics from the portable character
// set. The first character of a name is not a digit"
// The following regexp is the lexical convention according to the bash
// implementation (ftp://ftp.gnu.org/gnu/bash/bash-4.1.tar.qz):
//auto bashEnvVariable = ctRegex!(`$[a-zA-Z ]+[a-zA-Z0-9 1*`);
// TODO: Add support for ‘{' and '}'
alias bashEnvVariable = ctRegex!(`\$([a-zA-Z_][a-zA-Z0-9_]*)`);
char[] expandEnvVariables(char[] text) {
  return replaceAll!(m => environment.get(m[1], "")) (text, bashEnvVariable) ;
}

int test() {
  if (mdFile == "none") {
    return 0;
  }

  const string CODE_BLOCK_FENCE = "```";
  const string CODE_BLOCK_COMMAND = "$ ";
  const string CODE_BLOCK_EXPECT_FAILURE = "# Expect failure";
  const string MARKDOWN_HEADING = "#";
  const string DISABLED_CODE_BLOCK = "**DISABLED**";

  bool insideCodeBlock = false;
  bool insideDisabledCodeBlock = false;
  bool expectPass = true;
  int exitStatus = 0;

  auto file = File(mdFile) ;
  auto range = file.byLine();

  foreach (line; range) {
    if (line.startsWith(DISABLED_CODE_BLOCK) && !runDisabled) {
      insideDisabledCodeBlock = true;
    }
    if (line.startsWith(CODE_BLOCK_FENCE)) {
      insideCodeBlock = !insideCodeBlock;
      insideDisabledCodeBlock = ( insideDisabledCodeBlock && insideCodeBlock) ;
    } else if (insideCodeBlock && !insideDisabledCodeBlock) {
      if (line.startsWith(CODE_BLOCK_EXPECT_FAILURE)) {
        expectPass = false;
      }
      if (line.startsWith(CODE_BLOCK_COMMAND)) {
        auto command = line[CODE_BLOCK_COMMAND.length..line.length];
        auto expandedCommand = expandEnvVariables(command);
        try {
          auto actualResult = execute(expandedCommand.split);
          if (actualResult.status == 0 && expectPass) {
            writeln(ANSI_COLOR_GREEN ~ "[  PASSED  ] " ~ ANSI_COLOR_RESET ~ command);
            if (verbose) {
              write(actualResult.output);
            }
          } else if (actualResult.status != 0 && !expectPass) {
            writeln(ANSI_COLOR_GREEN ~ "[  PASSED  ] " ~ ANSI_COLOR_RESET ~ command);
            if (verbose){
              write(actualResult.output);
            }
          } else {
            writeln(ANSI_COLOR_RED ~ "[  FAILED  ] " ~ ANSI_COLOR_RESET ~ command);
            write(actualResult.output);
            exitStatus = 1;
          }
        } catch (Exception e) {
          writeln(ANSI_COLOR_RED ~ "[  FAILED  ] " ~ ANSI_COLOR_RESET ~ command);
          exitStatus = 1;
          stderr.writeln(e.msg);
        }

        if (exitStatus == 1 && breakOnFailure) {
          return exitStatus;
        }
        expectPass = true;
      }
    } else { // Outside code block
      if (line.startsWith(MARKDOWN_HEADING)) {
        if(showHeaders || showAllMdLines) {
          if(useSpace){
            writeln("");
          }
          if(useBold) {
            writeln(ANSI_BOLD ~ line ~ ANSI_COLOR_RESET);
          } else {
            writeln(line);
          }
        }
      } else if (showAllMdLines) {
        writeln(line);
      }
    }
  }

  return exitStatus;
}

int main(string[] args) {
  try {
    auto result = getopt(
      args,
      std.getopt.config.bundling,
      std.getopt.config.required,
      "mdfile|f", "Use a specific Markdown (.md) file.", &mdFile,
      "verbose|v", "Output extra infromation.", &verbose,
      "headers|t", "Output Markdown Headers", &showHeaders,
      "bold|b",    "        |-- with bold.", &useBold,
      "space|s",   "        `-- with line separation.", &useSpace,
      "all|a",     "Output Markdown Lines.", &showAllMdLines,
      "run_diabled|d", "Also run disabled test cases.", &runDisabled,
      "break_on_failuire|q", "Break run of tests on failure.", &breakOnFailure);
      if (result.helpWanted) {
        defaultGetoptPrinter(ANSI_BOLD ~ "DESCRIPTION:" ~ ANSI_COLOR_RESET ~ "
The tool accepts a markdown (.md) file as input and verifies the correctness of
unix shell style code blocks. All lines starting with $ gets executed as if they
were actual unix commands. The tool then verifies that the issued command
returns as expected. If a failure is expected, this can be specified using an
\"# Expect failure\" comment just before the command is executed.

" ~ ANSI_BOLD ~ "EXAMPLE:" ~ ANSI_COLOR_RESET ~ "
```
echo \"int main(){};\" > ok_file.c
gcc -c ok_file.c
# Expect failure:
gcc -c missing_file.c
```

" ~ ANSI_BOLD ~ "OPTIONS:" ~ ANSI_COLOR_RESET, result.options);
        return 0;
      } else {
        return test();
      }
  } catch (Exception e) {
    stderr.writeln(e.msg);
    return 1;
  }
}