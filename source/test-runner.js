/*****************************************************************************
*
*                      Higgs JavaScript Virtual Machine
*
*  This file is part of the Higgs project. The project is distributed at:
*  https://github.com/maximecb/Higgs
*
*  Copyright (c) 2011, Maxime Chevalier-Boisvert. All rights reserved.
*
*  This software is licensed under the following license (Modified BSD
*  License):
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions are
*  met:
*   1. Redistributions of source code must retain the above copyright
*      notice, this list of conditions and the following disclaimer.
*   2. Redistributions in binary form must reproduce the above copyright
*      notice, this list of conditions and the following disclaimer in the
*      documentation and/or other materials provided with the distribution.
*   3. The name of the author may not be used to endorse or promote
*      products derived from this software without specific prior written
*      permission.
*
*  THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
*  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
*  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
*  NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
*  NOT LIMITED TO PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
*  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
*  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*****************************************************************************/

/*
Test-runner runs all js files in the specified dir in a forked instance of higgs.
If any tests fail the program exist abnormally (i.e. exit(1);)
*/

// Used to communicate with child test processes

(function()
{
    var ffi = require("lib/ffi");
    var std = require("lib/stdlib");
    var fs = require("lib/dir");
    var console = require("lib/console");
    var test = require("lib/test");
    var io = require("lib/stdio");

    var tests_dir = "./tests";
    var ignore_dir = "core";

    var tests_run = 0;
    var tests_passed = 0;
    var tests_failed = 0;

    var current = "";

    var child_status = std.malloc(2);

    function runTest(file)
    {
        file = current + "/" + file;
        var msg = "Running: " + file + "...";
        var pad_len = 60 - msg.length;

        while(pad_len--)
        {
            msg += " ";
        }

        // fork before running test
        var pid = ffi.c.fork();

        if (pid < 0)
        {
            console.log("FORK FAILED!");
            std.exit(1);
        }


        if (pid === 0)
        {
            // run the test in this child process
            try
            {
                load(file);
                tests_run += 1;
            }
            catch (e)
            {
                console.log(msg, "FAILED!");
                if (e && e.hasOwnProperty("message"))
                    console.log(e.message);
                else if (typeof e === "string")
                    console.log(e);

                std.exit(1);
            }

            // offset 'PASSED!' so 'FAILED!' sticks out more
            console.log(msg, "        PASSED!");
            std.exit(0);

        }
        else
        {
            // parent, wait for test to finish
            ffi.c.waitpid(pid, child_status, 0);
            tests_run +=1;
            // pull out return code and check for pass/fail
            if ($ir_load_u8(child_status, 1) !== 0)
                tests_failed += 1;
            else
                tests_passed += 1;
        }
    }

    function runTests(dir_name)
    {
        var dir = fs.dir(dir_name);
        var dirs = dir.getDirs().sort();
        var files = dir.getFiles().sort().filter(function(name)
        {
            var ext = name.substr(name.length - 3);
            return ext === ".js";
        });

        // first run tests in this dir
        current = dir_name;
        files.forEach(runTest);
        dirs.forEach(function(next_dir)
        {
            runTests(dir_name + "/" + next_dir);
        });
    }

    console.log("Starting test-runner.js...");
    console.log(" --- ");

    // We need to ignore the dir which contains test files run in unittest {} blocks in D
    var dir = fs.dir(tests_dir);

    var dirs = dir.getDirs().sort().filter(function(n)
    {
        return n !== ignore_dir;
    });

    var files = dir.getFiles().sort().filter(function(name)
    {
        var ext = name.substr(name.length - 3);
        return ext === ".js";
    });

    // first run tests in this dir
    current = tests_dir;
    files.forEach(runTest);
    dirs.forEach(function(next_dir)
    {
        runTests(tests_dir + "/" + next_dir);
    });

    console.log("test-runner.js results:");
    console.log(" --- ");
    console.log("Tests run:", tests_run);
    if (tests_run !== tests_passed)
        console.log("Tests passed:", tests_passed);
    console.log("Tests failed:", tests_failed);

    if (tests_failed)
        std.exit(1);
})();

