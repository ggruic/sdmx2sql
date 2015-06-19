# sdmx2sql
Ruby scripts for converting SDMX files into SQL statements

**NOTE:** Those scripts are only proof of concept, not a complete solution.
https://medium.com/@ggruic/how-to-pour-some-sdmx-data-into-sqlite-db-with-ruby-3fb89e53ba68

## Installation

Clone the repository and execute:

    $ bundle
  
## Usage

Parse SDMX DSD file (SDMX 2.0)

```Ruby
ruby parse_dsd.rb NA_SEC+ESTAT+v2_0+1.5.xml SQLITE
```

You should be able to see newly created file named NA_SEC+ESTAT+v2_0+1.5.xml_SQLITE_ddl in /result folder.
Go to SQLite and execute statements from this file. 
You'll get working instance of SQLite 3 database.

Or, use this ruby script (it's a bit slow, but never mind)

```Ruby
ruby load_dsd_ddl.rb result/NA_SEC+ESTAT+v2_0+1.5.xml_SQLITE_ddl NA_SEC.SQLITE3
```


Parse SDMX Data file (Compact)

```Ruby
ruby parse_sdmx_series.rb example_sdmx_data.xml SQLITE NA_SEC+ESTAT+v2_0+1.5.xml
```

You should be able to see newly created file named example_sdmx_data.xml_SQLITE_dml in /result folder.
Go to SQLite and execute statements from this file. 
Your SDMX data will be inserted into NA_SEC.SQLITE3 database.



## Maintainers

* [Goran Gruić](https://twitter.com/ggruic)

## Contributing

1. Fork it ( http://github.com/ggruic/sdmx2sql/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
