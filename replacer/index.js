var fs            = require("fs")
   ,path          = require("path")
   ,console       = require("console")
   ,args          = process.argv.filter(function(s){return false === /node\.exe/i.test(s) && false === /index\.js/i.test(s);})
   ,regex_extract = /^\/(.+)\/([gimu]{0,1})$/
   ,file
   ,pattern_search
   ,pattern_replace
   ,parsed
   ,content
   ;

if(args.length < 3){
  console.log("'Replace-with' pattern is missing. If you wish to replace with empty string (delete) you must specify \"\".");
  process.exit();
}

//normalise
file            = path.resolve(args[0]);
pattern_search  = Buffer.from(args[1],'base64').toString('utf-8');
pattern_replace = "" === pattern_replace ? "" : Buffer.from(args[2],'base64').toString('utf-8');

//verify has 'regex like' search-pattern.
if(false === regex_extract.test(pattern_search)){ console.log(args[1], "does not look like regular-expression.");                    process.exit(); }

//ok to extract and build actual-regex
pattern_search = pattern_search.match(regex_extract);
pattern_search = new RegExp(pattern_search[1], (pattern_search[2] || "")); //body and modifiers

content = fs.readFileSync(file,{encoding: "ascii"});
content = content.replace(pattern_search, pattern_replace);

parsed  = path.parse(file);
fs.writeFileSync(file, content, {flag:"w", encoding:"ascii"}); //overwrite
/*
//don't overwrite.
fs.writeFileSync( parsed.dir + "/" + parsed.name + "_fixed" + parsed.ext
                , content
                , {flag:"w", encoding:"ascii"}
                );
*/