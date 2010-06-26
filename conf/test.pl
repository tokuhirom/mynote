{
    'DB' => [
        'dbi:mysql:database=test_MyNote;mysql_enable_utf8=1;mysql_read_default_file=/etc/mysql/my.cnf',
        'test',
        '',
        {RaiseError => 1, AutoCommit => 0},
    ],
    'app' => {
    }
}
