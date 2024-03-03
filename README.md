A copy of the parser combinator code as shown in ["Parsing from first principles" by Saša Jurić](https://www.youtube.com/watch?v=xNzoerDljjo), hand typed by me.

This parser is designed to work on this subset of SQL:

    select col1 from (
        select col2, col3 from (
            select col4, col5, col6 from some_table
        )
    )

The commit history will walk through the processes of building this up from scratch.
    
