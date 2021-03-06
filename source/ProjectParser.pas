unit ProjectParser;

interface

uses ExpressionParser, system.Classes,  Variables, output, SysUtils, Project,
     TagType, tagParser, TokenProcessor, NovusEnvironment;


type
   tProjectParser = class
   protected
   private
   public
     class function ParseProject(aItemName: String; aProject: tProject; aOutput: tOutput): String;
   end;


implementation

uses VariablesCmdLine, NovusTemplate, Config, CodeGenerator;

class function tProjectParser.ParseProject(aItemName: String; aProject: tProject; aOutput: tOutput): String;
var
  lEParser: tExpressionParser;
  lTokens: tTokenProcessor;
  loTemplate: tNovusTemplate;
  I: Integer;
  FTemplateTag: TTemplateTag;
  lsToken1: String;
  lsToken2: String;
  FTagType: TTagType;
  lVariable: TVariable;
begin
  Result := '';

  if aItemName= '' then Exit;


  loTemplate := NIL;
  lTokens := NIL;
  lEParser := NIL;

  Try

    lEParser:= tExpressionParser.Create;
    lTokens:= tTokenProcessor.Create;
    loTemplate := tNovusTemplate.Create;

    loTemplate.StartToken := '[';
    loTemplate.EndToken := ']';
    loTemplate.SecondToken := '%';

    loTemplate.TemplateDoc.Text := Trim(aItemName);

    loTemplate.ParseTemplate;

    For I := 0 to loTemplate.TemplateTags.Count -1 do
       begin
         lTokens.Clear;

         FTemplateTag := TTemplateTag(loTemplate.TemplateTags.items[i]);

         lEParser.Expr := FTemplateTag.TagName;
         lEParser.ListTokens(lTokens);

         FTagType := TTagParser.ParseTagType(NIL, NIL,lTokens, aOutput, 0);

         case FtagType of
           ttworkingdirectory:
             begin
               FTemplateTag.TagValue := aProject.GetWorkingDirectory;
             end;

           ttVariableCmdLine:
              begin
                lsToken1 := lTokens.GetFirstToken;
                lsToken2 := lTokens.GetNextToken;

                lVariable := oConfig.oVariablesCmdLine.GetVariableByName(lsToken2);

                if Assigned(lVariable) then
                  FTemplateTag.TagValue := lvariable.Value;

              end
           else
             FTemplateTag.TagValue := aProject.oProjectConfigLoader.Getproperties(FTemplateTag.TagName);
         end;
       end;

    loTemplate.InsertAllTagValues;

    Result := Trim(loTemplate.OutputDoc.Text);
  Finally
    if Assigned(loTemplate) then loTemplate.Free;
    if assigned(lTokens) then lTokens.Free;
    if assigned(lEParser) then lEParser.Free;
  End;

  Result :=  tNovusEnvironment.ParseGetEnvironmentVar(Result,ETTToken2 );

  //Result :=  tNovusEnvironment.ParseGetEnvironmentVar(Result, ETTToken1);

end;



end.
