# MDTEST

mdtest is a tool that accepts a markdown (.md) file as input and verifies the 
correctness of unix shell style code blocks. All lines starting with `$` gets 
executed as if they were actual unix commands. The tool then verifies that the 
issued command returns as expected (based on its exit code). If a failure is expected, this can be 
specified using an `# Expected failure` comment just before the command is 
executed.

## Usage

This section shows an example where we use `mdtest` to verify that gcc returns
the correct exit code for some ok and not ok program:

Create some example data to use for our test:
```
$ echo "int main(){};" > ok_file.c
$ echo "bad syntax" > bad_file.c
```

Write some example `README.md` file with some code blocks:

```
$ gcc -c ok_file.c

# Expect failure:
$ gcc -c bad_file.c
```

Run mdtest:

```
mdtest -f README.md
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
