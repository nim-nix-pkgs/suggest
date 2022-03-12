{
  description = ''mmap-persistent SymSpell spell checking algorithm'';

  inputs.flakeNimbleLib.owner = "riinr";
  inputs.flakeNimbleLib.ref   = "master";
  inputs.flakeNimbleLib.repo  = "nim-flakes-lib";
  inputs.flakeNimbleLib.type  = "github";
  inputs.flakeNimbleLib.inputs.nixpkgs.follows = "nixpkgs";
  
  inputs.src-suggest-v1_1.flake = false;
  inputs.src-suggest-v1_1.owner = "c-blake";
  inputs.src-suggest-v1_1.ref   = "refs/tags/v1.1";
  inputs.src-suggest-v1_1.repo  = "suggest";
  inputs.src-suggest-v1_1.type  = "github";
  
  inputs."cligen".dir   = "nimpkgs/c/cligen";
  inputs."cligen".owner = "riinr";
  inputs."cligen".ref   = "flake-pinning";
  inputs."cligen".repo  = "flake-nimble";
  inputs."cligen".type  = "github";
  inputs."cligen".inputs.nixpkgs.follows = "nixpkgs";
  inputs."cligen".inputs.flakeNimbleLib.follows = "flakeNimbleLib";
  
  outputs = { self, nixpkgs, flakeNimbleLib, ...}@deps:
  let 
    lib  = flakeNimbleLib.lib;
    args = ["self" "nixpkgs" "flakeNimbleLib" "src-suggest-v1_1"];
  in lib.mkRefOutput {
    inherit self nixpkgs ;
    src  = deps."src-suggest-v1_1";
    deps = builtins.removeAttrs deps args;
    meta = builtins.fromJSON (builtins.readFile ./meta.json);
  };
}