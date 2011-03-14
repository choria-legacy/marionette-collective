<?php
class MCollectiveAction {
    public $infile = "";
    public $outfile = "";
    public $request = array();

    function __construct() {
        if (!isSet($_ENV["MCOLLECTIVE_REQUEST_FILE"])) {
            throw new Exception("no MCOLLECTIVE_REQUEST_FILE environment variable");
        }

        if (!isSet($_ENV["MCOLLECTIVE_REPLY_FILE"])) {
            throw new Exception("no MCOLLECTIVE_REPLY_FILE environment variable");
        }

        $this->infile = $_ENV["MCOLLECTIVE_REQUEST_FILE"];
        $this->outfile = $_ENV["MCOLLECTIVE_REPLY_FILE"];

        $this->readJSON();
    }

    function __destruct() {
        $this->save();
    }

    function readJSON() {
        $this->request = json_decode(file_get_contents($this->infile), true);
        unset($this->request["data"]["process_results"]);
    }

    function save() {
        file_put_contents($this->outfile, json_encode($this->request["data"]));
    }

    // prints a line to STDERR that will log at error level in the
    // mcollectived log file
    function error($msg) {
        fwrite(STDERR, "$msg\n");
    }

    // prints a line to STDOUT that will log at info level in the
    // mcollectived log file
    function info($msg) {
        fwrite(STDOUT, "$msg\n");
    }

    // logs an error message and exits with RPCAborted
    function fail($msg) {
        $this->error($msg);
        exit(1);
    }

    function __get($property) {
        if (isSet($this->request[$property])) {
            return $this->request[$property];
        } else {
            throw new Exception("No $property in request");
        }
    }

    function __set($property, $value) {
        $this->request["data"][$property] = $value;
    }
}
?>
