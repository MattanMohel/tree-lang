A small language for creating tree objects

## Structure

```
A(0, 0)
B(1, 0)
C(1, 1)
D(0, 1)

| A B C D A
```

This creates the following structure:

```
A - B
|   |
D - C
```

You can also use `[]` to create sub-connections:

```
| A [C D] B C D A
```

This means that `A` also connects to `C` and `D`

## Why?

This was a small excursion, but it will help me represent maps as trees of nodes to make the implmenetation of path-finding algorithms easier