vector Axes = ZERO_VECTOR;      
integer Delete = FALSE;            
string MapAxis;                    
vector Maxima = ZERO_VECTOR;    
integer MenuListen;              
vector Minima;                    
vector Scale;                    

CloseListen(){
  
    llSetTimerEvent(0.0);
    if(MenuListen){
        llListenRemove(MenuListen);
        MenuListen = 0;
    }
}

float Map(integer Axis){
  
    string Use = llGetSubString(MapAxis, Axis, Axis);
    if("X" == Use){return Scale.x;}
    if("Y" == Use){return Scale.y;}
    if("Z" == Use){return Scale.z;}
    llOwnerSay("Map Failure: " + (string) MapAxis);
    return 1.0;
}

Menu(){
  
    list MenuButtons = ["Restore", "Exit", "Delete"];
    string MenuMessage = "Scale:\nMax: " + (string) Maxima + "\nNow: " + (string) Scale + "\nMin: " + (string) Minima;

    if(Delete){
    
        MenuButtons = ["Confirm", "Cancel"];
        MenuMessage = "Are you sure you want to delete this resize script?";
    }else{
    
        if(Axes.x){MenuButtons += ["X •"];}else{MenuButtons += ["X"];}
        if(Axes.y){MenuButtons += ["Y •"];}else{MenuButtons += ["Y"];}
        if(Axes.z){MenuButtons += ["Z •"];}else{MenuButtons += ["Z"];}
        MenuButtons += ["-0.05","-0.10","-0.25", "+0.05","+0.10","+0.25"];
    }

  
    integer MenuChannel = -(integer) (llFrand(999999999.9) + 1);
    MenuListen = llListen(MenuChannel, "", llGetOwner(), "");
    llDialog(llGetOwner(), MenuMessage, MenuButtons, MenuChannel);
    llSetTimerEvent(30.0);
}

Resize(){
  
    if(Scale.x < Minima.x){Scale.x = Minima.x;}else if(Scale.x > Maxima.x){Scale.x = Maxima.x;}
    if(Scale.y < Minima.y){Scale.y = Minima.y;}else if(Scale.y > Maxima.y){Scale.y = Maxima.y;}
    if(Scale.z < Minima.z){Scale.z = Minima.z;}else if(Scale.z > Maxima.z){Scale.z = Maxima.z;}

    
    string Axis;
    integer Counter = llGetNumberOfPrims();
    integer Index;
    vector NewPos;
    vector NewSize;
    list Originals;
       rotation RootRot = llGetRootRotation();
    if(1 == Counter){
      
        Originals = llParseString2List(llList2String(llGetLinkPrimitiveParams(0, [PRIM_TEXT]), 0), ["?"], []);
        NewSize = (vector) llList2String(Originals, 0);
        NewSize.x *= Scale.x;
        NewSize.y *= Scale.y;
        NewSize.z *= Scale.z;
        llSetLinkPrimitiveParamsFast(0, [PRIM_SIZE, NewSize]);
    }else{
      
        while(Counter){
            Originals = llParseString2List(llList2String(llGetLinkPrimitiveParams(Counter, [PRIM_TEXT]), 0), ["?"], []);
            NewSize = (vector) llList2String(Originals, 0);
            MapAxis = llList2String(Originals, 1);
        
            if("!!!" != MapAxis){
                NewSize.x *= Map(0);
                NewSize.y *= Map(1);
                NewSize.z *= Map(2);
            }
            NewPos = (vector) llList2String(Originals, 2);
            NewPos.x *= Scale.x;
            NewPos.y *= Scale.y;
            NewPos.z *= Scale.z;
            if(1 == Counter){
              
                llSetLinkPrimitiveParamsFast(Counter--, [PRIM_SIZE, NewSize]);
            }else{
              
                llSetLinkPrimitiveParamsFast(Counter--, [PRIM_SIZE, NewSize, PRIM_POSITION, NewPos]);
            }
        }
    }


    Menu();
}

string RoundVec(vector In){
    return "<" + (string) llRound(In.x) + "," + (string) llRound(In.y) + "," + (string) llRound(In.z) + ">";
}

string TrimFloat(float In){
  
    string Temp = (string) In;
    while("0" == llGetSubString(Temp, -1, -1)){Temp = llDeleteSubString(Temp, -1, -1);}
    if("." == llGetSubString(Temp, -1, -1)){Temp = llDeleteSubString(Temp, -1, -1);}
    return Temp;
}

string TrimVec(vector In){
  
    return "<" + TrimFloat(In.x) + "," + TrimFloat(In.y) + "," + TrimFloat(In.z) + ">";
}

default{
    link_message(integer FromPrim, integer Number, string Text, key UUID){
    
        if("RESIZEQUERY" == Text){
          
            llMessageLinked(FromPrim, Number, (string) Maxima + "_" + (string) Scale + "_" + (string) Minima, UUID);
        }else if("RESIZE:" == llGetSubString(Text, 0, 6)){
          
            Scale = (vector) llDeleteSubString(Text, 0, 6);
            Resize();
        }
    }

    listen(integer ChannelIn, string FromName, key FromID, string Message){
      
        CloseListen();
        if((float) Message){
          
            if(Axes.x){Scale.x += (float) Message;}
            if(Axes.y){Scale.y += (float) Message;}
            if(Axes.z){Scale.z += (float) Message;}
            Resize();
        }else{
      
            if("Cancel" == Message){
            
                Delete = FALSE;
                Menu();
            }else if("Confirm" == Message){
              
                integer Counter = llGetNumberOfPrims();
                if(1 == Counter){
                    llSetLinkPrimitiveParamsFast(0, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
                }else{
                    while(Counter){
                        llSetLinkPrimitiveParamsFast(Counter--, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
                    }
                }
                llOwnerSay("Script deleted");
                llRemoveInventory(llGetScriptName());
            }else if("Delete" == Message){
              
                Delete = TRUE;
                Menu();
            }else if("Exit" == Message){
          
            }else if("Restore" == Message){
            
                if(Axes.x){Scale.x = 1.0;}
                if(Axes.y){Scale.y = 1.0;}
                if(Axes.z){Scale.z = 1.0;}
                Resize();
            }else{
                Message = llGetSubString(Message, 0, 0);
                if("X" == Message){Axes.x = !(integer) Axes.x;}
                else if("Y" == Message){Axes.y = !(integer) Axes.y;}
                else if("Z" == Message){Axes.z = !(integer) Axes.z;}
                Menu();
            }
        }
    }

    state_entry(){
    
        llOwnerSay("Initialising, please wait ...");
        integer Counter = llGetNumberOfPrims();
        float MaxDim = 10.0;
        float MinDim = 0.01;
        if(1 == Counter){
          
            Maxima = llList2Vector(llGetLinkPrimitiveParams(0, [PRIM_SIZE]), 0);
            Minima = Maxima;
            llSetLinkPrimitiveParamsFast(Counter, [PRIM_TEXT, TrimVec(Maxima), ZERO_VECTOR, 0.0]);
        }else{
          
            list AxisMap = ["<0,0,0>", "XYZ", "<0,0,90>", "YXZ", "<0,0,180>", "XYZ", "<0,0,-90>", "YXZ", "<0,90,0>", "ZYX",
                "<0,90,90>", "YZX", "<0,90,-180>", "ZYX", "<0,90,-90>", "YZX", "<180,0,180>", "XYZ", "<180,0,-90>", "YXZ",
                "<180,0,0>", "XYZ", "<-180,0,90>", "YXZ", "<0,-90,0>", "ZYX", "<0,-90,90>", "YZX", "<0,-90,-180>", "ZYX",
                "<0,-90,180>", "ZYX", "<0,-90,-90>", "YZX", "<90,0,0>", "XZY", "<90,0,90>", "ZXY", "<90,0,180>", "XZY", "<90,0,-90>", "ZXY",
                "<-90,0,180>", "XZY", "<-90,0,-90>", "ZXY", "<-90,0,0>", "XZY", "<-90,0,90>", "ZXY", "<-180,0,0>", "XYZ"];
            integer Index;
            string LinkRot;
            vector LinkScale;
            Minima = <MaxDim, MaxDim, MaxDim>;
            vector RootPos = llGetPos();
            rotation WasRot = llGetRot();
            llSetRot(ZERO_ROTATION);
            while(Counter){
          
                LinkRot = RoundVec(llRot2Euler(llList2Rot(llGetLinkPrimitiveParams(Counter, [PRIM_ROTATION]), 0) / ZERO_ROTATION) * RAD_TO_DEG);
                LinkScale = llList2Vector(llGetLinkPrimitiveParams(Counter, [PRIM_SIZE]), 0);
                Index = llListFindList(AxisMap, [LinkRot]);
                if(++Index){
                  
                    Scale = LinkScale;
                    MapAxis = llList2String(AxisMap, Index);
                    LinkScale.x = Map(0);
                    LinkScale.y = Map(1);
                    LinkScale.z = Map(2);
                    if(LinkScale.x < Minima.x){Minima.x = LinkScale.x;}else if(LinkScale.x > Maxima.x){Maxima.x = LinkScale.x;}
                    if(LinkScale.y < Minima.y){Minima.y = LinkScale.y;}else if(LinkScale.y > Maxima.y){Maxima.y = LinkScale.y;}
                    if(LinkScale.z < Minima.z){Minima.z = LinkScale.z;}else if(LinkScale.z > Maxima.z){Maxima.z = LinkScale.z;}
                }else{
                  
                    MapAxis = "!!!";
                    llOwnerSay("Link " + (string) Counter + " unhandled rotation " + LinkRot + " - won't be resized");
                }
                llSetLinkPrimitiveParamsFast(Counter, [PRIM_TEXT, TrimVec(LinkScale) + "?" + MapAxis + "?" +
                    TrimVec((llList2Vector(llGetLinkPrimitiveParams(Counter--, [PRIM_POSITION]), 0) - RootPos) / ZERO_ROTATION),
                    ZERO_VECTOR, 0.0]);
            }
            llSetRot(WasRot);
        }
  
        Maxima.x = MaxDim / Maxima.x;
        Maxima.y = MaxDim / Maxima.y;
        Maxima.z = MaxDim / Maxima.z;
        Minima.x = MinDim / Minima.x;
        Minima.y = MinDim / Minima.y;
        Minima.z = MinDim / Minima.z;
        Scale = <1.0, 1.0, 1.0>;
        llOwnerSay("Ready - touch for menu");
    }

    timer(){
  
        llOwnerSay("Menu timed-out.  Touch again to reactivate it");
        Delete = FALSE;
        CloseListen();
    }

    touch_start(integer HowMany){
    
        if(llDetectedKey(0) == llGetOwner()){
            CloseListen();
            Menu();
        }
    }
}