#!perl
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => "MCollective::Action",
    PREREQ_PM => {
        "JSON" => 0,
    },
);
