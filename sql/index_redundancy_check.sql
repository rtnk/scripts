WITH i
  AS (SELECT s.name AS schema_name,
             t.name AS table_name,
             i.name AS index_name,
             c.name AS column_name,
             ic.index_column_id
        FROM sys.indexes i
        JOIN sys.index_columns ic
          ON i.object_id  = ic.object_id
         AND i.index_id   = ic.index_id
        JOIN sys.columns c
          ON ic.object_id = c.object_id
         AND ic.column_id = c.column_id
        JOIN sys.tables t
          ON i.object_id  = t.object_id
        JOIN sys.schemas s
          ON t.schema_id  = s.schema_id),
     indexes
  AS (SELECT schema_name,
             table_name,
             index_name,
             STUFF((SELECT ',' + j.column_name
                      FROM i j
                     WHERE i.table_name = j.table_name
                       AND i.index_name = j.index_name
                 FOR XML PATH('') -- Yay, XML in SQL!
                 ),
                   1,
                   1,
                   '') columns
        FROM i
       GROUP BY schema_name,
                table_name,
                index_name)
SELECT i.schema_name,
       i.table_name,
       i.index_name AS "Deletion candidate index",
       i.columns AS "Deletion candidate columns",
       j.index_name AS "Existing index",
       j.columns AS "Existing columns"
  FROM indexes i
  JOIN indexes j
    ON i.schema_name = j.schema_name
   AND i.table_name  = j.table_name
   AND j.columns LIKE i.columns + ',%';
