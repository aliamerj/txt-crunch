# txt-crunch
Txt-Crunch is a command-line tool for text file compression using Huffman coding. This tool efficiently compresses text files, reducing their size and making them easier to store and transfer.

## Inspiration
This project is inspired by a coding challenge from [Coding Challenges](https://codingchallenges.fyi/challenges/challenge-huffman). The challenge provided the idea to implement Huffman coding, a popular algorithm for lossless data compression.

## Features
- Efficient Compression: Uses Huffman coding to compress text files, significantly reducing their size.
- Command-Line Interface: Easy-to-use CLI for compressing files.
- Flexible Memory Management: Uses Zig's memory allocation strategies to manage resources efficiently.

## Usage
To compress a text file, run the following command:
```bash
zig build run -- <file_path>
```
Example:

```bash
zig build run -- example.txt
```
