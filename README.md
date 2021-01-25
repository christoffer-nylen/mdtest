# mdtest

mdtest accepts a markdown (.md) file as input and executes each code block
as if it was a series of unix shell commands. 

A **PASSED** or **FAILED** will be presented for each block based on the result
(exit code) of the commands.

Lines beginning with `$` will be interpreted as a unix command. 

If a failure is expected, this can be specified using a `# Expected failure` in 
the previous row.

## Example

Write some example `README.md` file with some code block:

```
$ gcc -c ok_file.c
# Expect failure:
$ gcc -c bad_file.c
```

Run mdtest:

```
$ mdtest -f README.md
```


## How to build mdtest

Build it using a D compiler, for example ldc.

```
ldc2 mdtest.d
```

## How to install a D compiler

Download a D compiler from [the official distribution page](https://github.com/ldc-developers/ldc/releases).

Example (2021-01-07):

```sh
wget https://github.com/ldc-developers/ldc/releases/download/v1.24.0/ldc2-1.24.0-linux-x86_64.tar.xz
tar -xf ldc2-1.24.0-linux-x86_64.tar.xz -C ~/dlang
```

Add it to your `$PATH`:
```
export PATH=~/dlang/ldc2-1.24.0-linux-x86_64/bin:$PATH
```
