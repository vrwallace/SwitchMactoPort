unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  snmpsend, winsock, synautil,strutils,pingsend, blcksock;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ciscoswitch: TEdit;
    lmessage: TEdit;
    Walkmemo: TMemo;
    scn: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure DumpExceptionCallStack(E: Exception; how: string);
    function GetIPAddress(hostname: string): string;
    function PingHostfun(const Host: string): string;
    function Pingtracertrttl(const Host: string): string;
     function TraceRouteHostfun(const Host: string): string;

     function HexStrToStr(const HexStr: string): string;
     function StrToHexStr(const S: string): string;
     function IPAddrToName(IPAddr: string): string;

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

function tform1.GetIPAddress(hostname: string): string;
type
  pu_long = ^u_long;
var
  varTWSAData: TWSAData;
  varPHostEnt: PHostEnt;
  varTInAddr: TInAddr;
  //namebuf : Array[0..255] of char;
begin
  if trim(hostname) = '' then
  begin
    Result := '';
    exit;
  end;

  if WSAStartup($101, varTWSAData) <> 0 then
    Result := ''
  else
  begin

    //gethostname(namebuf,sizeof(namebuf));
    try
      varPHostEnt := gethostbyname(PAnsiChar(hostname));
      varTInAddr.S_addr := u_long(pu_long(varPHostEnt^.h_addr_list^)^);
      Result := inet_ntoa(varTInAddr);
    except
      on E: Exception do
        Result := '';
    end;
  end;
  WSACleanup;
end;

procedure TForm1.DumpExceptionCallStack(E: Exception; how: string);
var
  I: integer;
  Frames: PPointer;
  Report: string;
begin
  Report := 'Program exception! ' + LineEnding + 'Stacktrace:' +
    LineEnding + LineEnding;
  if E <> nil then
  begin
    Report := Report + 'Exception class: ' + E.ClassName + LineEnding +
      'Message: ' + E.Message + LineEnding;

    Report := Report + BackTraceStrFunc(ExceptAddr);
    Frames := ExceptFrames;
    for I := 0 to ExceptFrameCount - 1 do
      Report := Report + LineEnding + BackTraceStrFunc(Frames[I]);
    if how = 'showmessage' then
    begin
      ShowMessage(Report);
      //halt;
    end
    else
    begin

      //logit(Tram(FormatDateTime('h:nn:ss AM/PM', now) + ' ' +
      // FormatDateTime('MM/DD/YYYY', now)) + ' ERROR: ' + report);

    end;
  end;
  //Halt; // End of program execution
end;

procedure TForm1.Button1Click(Sender: TObject);
var


  arr: array of array of string;
  foundip:string;
  foundcount:integer;
  arraysize:integer;
  arrayindex:integer;
  SNMPResult: boolean;
  Result: string;
  snmpval, ipaddrval : string;
  baseoid: string;
  OID: string;
  s: ansistring;
  ip:string;
  mactemp:string;
  macval,code:integer;
  list:tstringlist;
  macindex:integer;
  macaddress:string;
begin

  try
  walkmemo.Clear;
  snmpval := scn.Text;
  macval:=0;

  ipaddrval := GetIPAddress(ciscoswitch.Text);
  if (ipaddrval = '') then
  begin
    lmessage.Text := 'Could not resolve IP Address!';
    application.ProcessMessages;
    ShowMessage('Could not resolve IP Address!');
    exit;
  end;

  lMessage.Text := 'Testing Connection...';
  application.ProcessMessages;

  SNMPResult := SNMPGet('1.3.6.1.2.1.1.1.0', SNMPval, ipaddrval, Result);
  if (SNMPResult <> True) then
  begin
    lmessage.Text := 'Failed test SNMPGet, check Community Name or Host!';
    application.ProcessMessages;
    ShowMessage('Failed test SNMPGet, check Community Name or Host!');
    exit;
  end;

  lMessage.Text := 'Getting MAC IP List...';


  baseoid := '1.3.6.1.2.1.4.22.1.2';
  oid := baseoid;

  arraysize:=0;

  repeat

    snmpResult := SNMPGetNext(oid, snmpval, ipaddrval, s);
    if (SNMPResult = True) then
      begin

    if (Pos(BaseOID, OID) <> 1) then
      break;


     for macindex:=1 to 6 do
       begin
         if (macindex=1) then
           begin
             val(s[macindex],macval,code);
             macaddress:=  StrToHexStr(s[macindex]);
         end
         else
         macaddress:=macaddress +'-'+ StrToHexStr(s[macindex]);
        end;

      List:=TStringList.Create;
     List.Delimiter:='.';
     List.DelimitedText:=oid;

     ip:=list[11]+'.'+list[12]+'.'+list[13]+'.'+list[14];
     list.free;
     //walkmemo.Lines.Add( macaddress+ #9 +   ip);
     //application.processmessages;
     SetLength(arr, 2,arraysize+2);
     arr[0][arraysize]:=macaddress;
     arr[1][arraysize]:=ip;
     arraysize:=arraysize+1;

      end;


  until not snmpresult;


  lMessage.Text := 'Getting MAC Port List...';


  baseoid := '1.3.6.1.2.1.17.4.3.1.2';
  oid := baseoid;


  walkmemo.Lines.Add('Results for Switch: '+ipaddrval);
  walkmemo.Lines.Add('Port' + #9 + 'MAC' +#9+ 'IP' +#9+'HOSTNAME');
  repeat

    snmpResult := SNMPGetNext(oid, snmpval, ipaddrval, s);
    if (SNMPResult = True) then
      begin

    if (Pos(BaseOID, OID) <> 1) then
      break;

     //mactemp:=midstr(oid,length(baseoid)+2,length(oid)-(length(baseoid)+1));

     List:=TStringList.Create;
     List.Delimiter:='.';
     List.DelimitedText:=oid;

     mactemp:=list[11]+'.'+list[12]+'.'+list[13]+'.'+list[14]+'.'+list[15]+'.'+list[16];
     list.free;

     List:=TStringList.Create;
     List.Delimiter:='.';
     List.DelimitedText:=mactemp;


     for macindex:=0 to 5 do
     begin
       if (macindex=0) then
       begin

      //if list[macindex]='' then showmessage(mactemp);
       macaddress:= inttohex( strtoint(list[macindex]),2);
       end
       else
       begin
       //if list[macindex]='' then showmessage('OID:'+oid+ '|'+ mactemp);
       macaddress:=macaddress +'-'+ inttohex( strtoint(list[macindex]),2);
       end;
      end;
     list.free;
     foundcount:=0;

     for arrayindex:=0 to arraysize do
     begin
     if (arr[0][arrayindex] = macaddress) then
     begin
       if (foundcount=0) then
       begin
       foundIP:= arr[1][arrayindex];
       foundcount:=foundcount+1
       end
       else
       begin
       foundIP:= foundip + '|'+ arr[1][arrayindex];
       foundcount:=foundcount+1
       end;
       end;

     end;



     if foundcount = 0 then foundIP:='';

     if (trim(foundip)<>'') then
     walkmemo.Lines.Add(s + #9 +   macaddress + #9 +foundip +#9+IPAddrToName(foundip))
     else
     walkmemo.Lines.Add(s + #9 +   macaddress + #9 +'' +#9+'');

     application.processmessages;
     end;
  until not snmpresult;

   SetLength(arr, 0,0);



  lMessage.Text := 'Complete!';

  except
    on E: Exception do
    begin
      lMessage.Text := 'Error Occured!';
      application.ProcessMessages;

      DumpExceptionCallStack(E, 'showmessage');
    end;

  end;

  end;

procedure TForm1.Button2Click(Sender: TObject);
begin

  lmessage.text:='';
  walkmemo.clear;
  walkmemo.Lines.add('Pinging...');
  application.ProcessMessages;
  walkmemo.Lines.add(pinghostfun(ciscoswitch.Text));

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
   lmessage.text:='';
   walkmemo.Clear;
  walkmemo.Lines.add('Tracerouting...');
  application.ProcessMessages;
  walkmemo.Lines.add(traceroutehostfun(ciscoswitch.Text));
end;

 function tform1.PingHostfun(const Host: string): string;
var
  low, high, timetotal, j, success: integer;
  ipaddrval: string;
begin
  Result := '';

  ipaddrval := GetIPAddress(host);
  if ipaddrval = '' then
  begin
    Result := 'Could not resolve IP Address!';
    application.ProcessMessages;
    exit;
  end;

  with TPINGSend.Create do

    try
      success := 0;
      timetotal := 0;
      low := 99999;
      high := 0;
      Result := 'Pinging ' + ipaddrval + ' with ' + IntToStr(PacketSize) +
        ' bytes of data:' + #13#10;
      for j := 1 to 4 do
      begin
        if Ping(ipaddrval) then
        begin
          if ReplyError = IE_NoError then
          begin
            Result := Result + 'Reply from ' + ReplyFrom + ': bytes=' +
              IntToStr(PacketSize) + ' time=' + IntToStr(PingTime) +
              ' TTL=' + IntToStr(Ord(TTL)) + #13#10;
            timetotal := timetotal + pingtime;
            success := success + 1;
            if pingtime < low then
              low := pingtime;
            if pingtime > high then
              high := pingtime;
          end

          else
            Result := Result + 'Reply from ' + ReplyFrom + ': ' +
              ReplyErrorDesc + #13#10;
        end
        else
        begin
          Result := Result + 'Ping Failed!' + #13#10;
          low := 0;
          break;
        end;
      end;

      Result := Result + #13#10 + 'Ping statistics for ' + ipaddrval + ':'#13#10;
      Result := Result + 'Packets: Sent = ' + IntToStr(j) + ', Received = ' +
        IntToStr(success) + ', Lost = ' + IntToStr(j - success) +
        ' (' + IntToStr(trunc((100 - ((success / j) * 100)))) + '% loss)' + #13#10;
      Result := Result + 'Approximate round trip times in milli-seconds: ' +
        IntToStr(timetotal) + 'ms' + #13#10;
      Result := Result + 'Minimum = ' + IntToStr(low) + 'ms, Maximum = ' +
        IntToStr(high) + 'ms, Average = ' + IntToStr(trunc(timetotal / j)) +
        'ms' + #13#10;

    finally
      Free;
    end;
end;

function tform1.Pingtracertrttl(const Host: string): string;
var
  j: integer;

begin

  Result := '';
  with TPINGSend.Create do
    try
      for j := 1 to 2 do
      begin
        if Ping(Host) then
        begin
          if ReplyError = IE_NoError then
          begin
            Result := Result + IntToStr(PingTime) + ' ms    ';
          end

          else
            Result := Result + '*     ';
        end
        else
          Result := Result + '*     ';
      end;

    finally
      Free;
    end;
end;

function tform1.TraceRouteHostfun(const Host: string): string;
var
  Ping: TPingSend;
  ttl: byte;
  hopcount: integer;
  ipaddrval: string;
begin

  ipaddrval := GetIPAddress(host);
  if ipaddrval = '' then
  begin
    Result := 'Could not resolve IP Address!';
    application.ProcessMessages;
    exit;
  end;

  hopcount := 0;
  Result := 'Tracing route to ' + ipaddrval + ' over a maximum of 30 hops' + crlf + crlf;

  Ping := TPINGSend.Create;
  try
    ttl := 1;
    repeat
      hopcount := hopcount + 1;
      ping.TTL := ttl;
      Inc(ttl);
      if ttl > 31 then
        Break;
      if not ping.Ping(ipaddrval) then
      begin
        Result := Result + IntToStr(hopcount) + '    ' + cAnyHost + ' Timeout' + CRLF;
        continue;
      end;
      if (ping.ReplyError <> IE_NoError) and (ping.ReplyError <>
        IE_TTLExceed) then
      begin
        Result := Result + IntToStr(hopcount) + '    ' + Ping.ReplyFrom +
          ' ' + Ping.ReplyErrorDesc + CRLF;
        break;
      end;

      Result := Result + IntToStr(hopcount) + '    ' + IntToStr(Ping.PingTime) +
        ' ms    ' + Pingtracertrttl(Ping.ReplyFrom) + Ping.ReplyFrom + CRLF;
    until ping.ReplyError = IE_NoError;

    Result := Result + crlf + 'Trace complete.';

  finally
    Ping.Free;
  end;
end;


function TForm1.HexStrToStr(const HexStr: string): string;


var


  ResultLen: Integer;


begin


  ResultLen := Length(HexStr) div 2;


  SetLength(Result, ResultLen);


  if ResultLen > 0 then

    SetLength(Result, HexToBin(Pointer(HexStr), Pointer(Result), ResultLen));


end;


function TForm1.StrToHexStr(const S: string): string;


var


 ResultLen: Integer;


begin


  ResultLen := Length(S) * 2;


  SetLength(Result, ResultLen);


  if ResultLen > 0 then


    BinToHex(Pointer(S), Pointer(Result), Length(S));


end;

function TForm1.IPAddrToName(IPAddr: string): string;
var
  SockAddrIn: TSockAddrIn;
 HostEnt: PHostEnt;
 WSAData: TWSAData;
begin
 WSAStartup($101, WSAData);
 SockAddrIn.sin_addr.s_addr := inet_addr(PChar(IPAddr));

  HostEnt := gethostbyaddr(@SockAddrIn.sin_addr.S_addr, 4, AF_INET);
if HostEnt <> nil then
    Result := StrPas(Hostent^.h_name)
  else
    Result := '';
end;





end.






