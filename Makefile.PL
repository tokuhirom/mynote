use inc::Module::Install;
name 'MyNote';
all_from 'lib/MyNote.pm';

# requires '';


readme_markdown_from 'lib/MyNote.pm';
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests('xt');
# use_test_base;
auto_include;
WriteAll;
