return{
["global font scale"]=1,
["colorPalette"]={},
["windowList"]={
  ["main hp bar"]={
    ["x"]=961,
    ["options"]={"NoTitleBar","NoResize","NoMove","NoScrollbar","AlwaysAutoResize",},
    ["optionsChanged"]=false,
    ["displayList"]={
      {
        ["widgetType"]="progressBar",
        ["args"]={
          ["width"]=1920,
          ["barGradient"]={
            {
              0,
              {1,0,0,1,},
              },
            {
              0.5,
              {0.65490196078431,1,1,1,},
              },
            {
              0.79999995231628,
              {0,1,0.65098039215686,1,},
              },
            {
              1,
              {1,1,1,1,},
              },
            },
          ["showFullBar"]=false,
          ["textColor"]={0,0,0,1,},
          ["height"]=97,
          ["progressFunction"]="Player HP",
          },
        },
      },
    ["openEditor"]=false,
    ["fontScale"]=3.8599998950958,
    ["y"]=0,
    ["openOptions"]=false,
    ["enabled"]=true,
    ["w"]=1920,
    ["textColor"]={1,1,1,1,},
    ["h"]=0,
    ["newWidgetType"]=4,
    ["transparent"]=false,
    },
  ["tp bar"]={
    ["x"]=96,
    ["options"]={"NoTitleBar","NoResize","NoMove","NoScrollbar","AlwaysAutoResize",},
    ["y"]=1050,
    ["displayList"]={
      {
        ["widgetType"]="progressBar",
        ["args"]={
          ["width"]=240,
          ["barGradient"]={
            {
              0,
              {0.50196078431373,0,1,1,},
              },
            {
              0.3299999833107,
              {0.25,0.35294117647059,1,1,},
              },
            {
              0.6599999666214,
              {0,0.70588235294118,1,1,},
              },
            {
              1,
              {1,1,1,1,},
              },
            },
          ["showFullBar"]=true,
          ["height"]=240,
          ["progressFunction"]="Player TP",
          },
        },
      },
    ["openEditor"]=false,
    ["fontScale"]=1,
    ["newWidgetType"]=4,
    ["openOptions"]=false,
    ["h"]=200,
    ["w"]=200,
    ["textColor"]={1,1,1,1,},
    ["enabled"]=true,
    ["optionsChanged"]=false,
    ["transparent"]=false,
    },
  ["buff timer bar"]={
    ["x"]=1790,
    ["options"]={"NoTitleBar","NoResize","NoMove","NoScrollbar","AlwaysAutoResize",},
    ["y"]=1052,
    ["displayList"]={
      {
        ["widgetType"]="progressBar",
        ["args"]={
          ["width"]=240,
          ["barGradient"]={
            {
              0,
              {0.37254901960784,0,0.25098039215686,1,},
              },
            {
              0.3299999833107,
              {0.71764705882353,0.10196078431373,0.3843137254902,1,},
              },
            {
              0.6599999666214,
              {1,0.20392156862745,0.57647058823529,1,},
              },
            {
              0.84999996423721,
              {1,1,1,1,},
              },
            {
              1,
              {1,1,1,1,},
              },
            },
          ["showFullBar"]=true,
          ["height"]=240,
          ["progressFunction"]="Player S/D/J/Z Timer",
          },
        },
      },
    ["openEditor"]=false,
    ["fontScale"]=1,
    ["newWidgetType"]=4,
    ["openOptions"]=false,
    ["h"]=200,
    ["w"]=240,
    ["textColor"]={1,1,1,1,},
    ["enabled"]=true,
    ["optionsChanged"]=false,
    ["transparent"]=false,
    },
  ["xp bar"]={
    ["x"]=819,
    ["options"]={"NoTitleBar","NoResize","NoMove","NoScrollbar","AlwaysAutoResize",},
    ["y"]=121,
    ["displayList"]={
      {
        ["widgetType"]="progressBar",
        ["args"]={
          ["overlayFunction"]="Player XP: to Next Level",
          ["width"]=380,
          ["textColor"]={0,0,0,1,},
          ["barColor"]={1,1,0,1,},
          ["height"]=14,
          ["progressFunction"]="Player XP: Level Progress",
          },
        },
      },
    ["openEditor"]=false,
    ["fontScale"]=1,
    ["newWidgetType"]=4,
    ["openOptions"]=false,
    ["h"]=26,
    ["w"]=191,
    ["textColor"]={1,1,1,1,},
    ["enabled"]=true,
    ["optionsChanged"]=false,
    ["transparent"]=false,
    },
  ["misc info"]={
    ["x"]=910,
    ["options"]={"NoTitleBar","NoResize","NoMove","NoScrollbar","AlwaysAutoResize",},
    ["optionsChanged"]=false,
    ["displayList"]={
      {
        ["widgetType"]="showString",
        ["args"]={["text"]="pack | bank | meseta | session | kXP/h | time",},
        },
      {
        ["widgetType"]="Show Composite String",
        ["args"]={
          ["sourceCS"]={
            {"Number of Inventory Slots Free",4,},
            " |  ",
            {"Number of Bank Slots Free",3,},
            " | ",
            {"Player Meseta Carried",6,},
            " | ",
            {"Session Time Elapsed",7,},
            " | ",
            {"kXP/Hour in Dungeon",5,},
            " | ",
            ["functionList"]={"Number of Inventory Slots Free","Number of Bank Slots Free","Player Meseta Carried","Session Time Elapsed","kXP/Hour in Dungeon",},
            ["displayString"]="  30 |  200 |      0",
            ["formatString"]="%4i |  %3i | %6i | %7i | %5i | ",
            },
          },
        },
      },
    ["openEditor"]=false,
    ["y"]=174,
    ["newWidgetType"]=2,
    ["openOptions"]=false,
    ["enabled"]=true,
    ["w"]=300,
    ["textColor"]={1,1,1,1,},
    ["h"]=71,
    ["fontScale"]=2,
    ["transparent"]=false,
    },
  ["monster list"]={
    ["x"]=1529,
    ["options"]={"NoTitleBar","NoResize","NoMove","","",},
    ["optionsChanged"]=false,
    ["displayList"]={
      {
        ["widgetType"]="show formatted list",
        ["args"]={
          ["format table"]={
            ["field list"]={"name","hp","hpMax",},
            ["field combo list"]={"hp","hpMax","statusFrozen","statusConfused","statusParalyzed","defTech","atkTech","name",["defTech"]=6,["atkTech"]=7,["statusConfused"]=4,["statusParalyzed"]=5,["hpMax"]=2,["hp"]=1,["name"]=8,["statusFrozen"]=3,},
            ["list source function"]="Monsters in Current Room",
            ["format data"]={
              {"name",0,},
              " ",
              {"hp",0,},
              "/",
              ["format string"]="%0s %0s/%0s",
              {"hpMax",0,},
              },
            },
          },
        },
      },
    ["openEditor"]=false,
    ["y"]=1068,
    ["fontScale"]=1,
    ["openOptions"]=false,
    ["enabled"]=true,
    ["newWidgetType"]=3,
    ["textColor"]={1,1,1,1,},
    ["h"]=264,
    ["w"]=282,
    ["transparent"]=false,
    },
  ["floor list"]={
    ["x"]=1721,
    ["optionsChanged"]=false,
    ["fontScale"]=1,
    ["y"]=706,
    ["displayList"]={
      {
        ["widgetType"]="show formatted list",
        ["args"]={
          ["format table"]={
            ["format data"]={
              {"index",2,},
              "> ",
              {"Native",0,},
              "/",
              {"A. Beast",0,},
              "/",
              {"Machine",0,},
              "/",
              {"Dark",0,},
              "|",
              {"Hit",0,},
              " - ",
              {"special",0,},
              " ",
              {"name",0,},
              " +",
              {"grind",0,},
              ["format string"]="%2s> %0s/%0s/%0s/%0s|%0s - %0s %0s +%0s",
              },
            ["subtype combo list"]={"barrier","frame","mag","meseta","technique disk","tool","unit","weapon",["unit"]=7,["technique disk"]=5,["mag"]=3,["barrier"]=1,["tool"]=6,["meseta"]=4,["frame"]=2,["weapon"]=8,},
            ["sub format table"]={
              ["mag"]={
                {"index",2,},
                "> ",
                {"color",8,},
                " ",
                {"name",8,},
                " ",
                {"def",2,},
                "d/",
                {"pow",2,},
                "p/",
                {"dex",2,},
                "d/",
                {"mind",2,},
                "m| sync:",
                {"sync",3,},
                " |iq: ",
                ["format string"]="%2s> %8s %8s %2sd/%2sp/%2sd/%2sm| sync:%3s |iq: %3s",
                {"iq",3,},
                },
              ["tool"]={
                {"index",2,},
                "> ",
                {"quantity",0,},
                "x ",
                ["format string"]="%2s> %0sx %0s",
                {"name",0,},
                },
              ["unit"]={
                {"index",2,},
                "> ",
                {"name",0,},
                ["format string"]="%2s> %0s",
                },
              ["barrier"]={
                {"index",2,},
                "> ",
                {"name",0,},
                " ",
                {"evade",0,},
                "/",
                {"evadeMax",0,},
                "e |",
                {"defense",0,},
                "/",
                {"defenseMax",0,},
                "d",
                ["format string"]="%2s> %0s %0s/%0se |%0s/%0sd",
                },
              ["technique disk"]={
                {"index",2,},
                "> ",
                {"name",0,},
                " lv",
                ["format string"]="%2s> %0s lv%0s",
                {"techniqueLevel",0,},
                },
              ["meseta"]={["format string"]="",},
              ["frame"]={
                {"index",2,},
                "> ",
                {"name",0,},
                " ",
                {"slots",0,},
                "s |",
                {"evade",0,},
                "/",
                {"evadeMax",0,},
                "e |",
                {"defense",0,},
                "/",
                {"defenseMax",0,},
                "d",
                ["format string"]="%2s> %0s %0ss |%0s/%0se |%0s/%0sd",
                },
              ["weapon"]={
                {"index",2,},
                "> ",
                {"Native",0,},
                "/",
                {"A. Beast",0,},
                "/",
                {"Machine",0,},
                "/",
                {"Dark",0,},
                "|",
                {"Hit",0,},
                " - ",
                {"special",0,},
                " ",
                {"name",0,},
                " +",
                {"grind",0,},
                ["format string"]="%2s> %0s/%0s/%0s/%0s|%0s - %0s %0s +%0s",
                },
              },
            ["list source function"]="Floor Items",
            ["subtype edit index"]="weapon",
            ["field combo list"]={"index","type","name","grind","wrapped","killcount","untekked","isSrank","SrankName","special","Native","A. Beast","Machine","Dark","Hit",["Hit"]=15,["isSrank"]=8,["wrapped"]=5,["Dark"]=14,["killcount"]=6,["Machine"]=13,["untekked"]=7,["A. Beast"]=12,["Native"]=11,["special"]=10,["index"]=1,["type"]=2,["SrankName"]=9,["name"]=3,["grind"]=4,},
            ["sub field table"]={
              ["mag"]={"index","color","name","def","pow","dex","mind","sync","iq",},
              ["tool"]={"index","quantity","name",},
              ["unit"]={"index","name",},
              ["barrier"]={"index","name","evade","evadeMax","defense","defenseMax",},
              ["technique disk"]={"index","name","techniqueLevel",},
              ["meseta"]={},
              ["frame"]={"index","name","slots","evade","evadeMax","defense","defenseMax",},
              ["weapon"]={"index","Native","A. Beast","Machine","Dark","Hit","special","name","grind",},
              },
            ["field list"]={"index","Native","A. Beast","Machine","Dark","Hit","special","name","grind",},
            },
          },
        },
      },
    ["openEditor"]=false,
    ["options"]={"NoTitleBar","","","","",},
    ["h"]=460,
    ["openOptions"]=false,
    ["newWidgetType"]=3,
    ["textColor"]={1,1,1,1,},
    ["enabled"]=true,
    ["w"]=400,
    ["transparent"]=false,
    },
  },
["show window list"]=true,
}