unit RuntimeProjectItems;

interface

Uses Output, ProjectItem, NovusFileUtils, Project, ProjectParser,
  SysUtils, Plugins,  System.RegularExpressions,
  NovusStringUtils, System.IOUtils;

type
  tRuntimeProjectItems = class
  protected
  private
    foPlugins: tPlugins;
    foOutput: TOutput;
    foProject: TProject;
  public
    constructor Create(aOutput: TOutput; aProject: TProject; aPlugins: tPlugins);
    destructor Destroy;

    function RunProjectItems: boolean;
  end;

implementation

constructor tRuntimeProjectItems.Create;
begin
  foOutput := aOutput;
  foProject := aProject;
  foPlugins := aPlugins
end;

destructor tRuntimeProjectItems.Destroy;
begin

end;

function tRuntimeProjectItems.RunProjectItems: boolean;
Var
  loProjectItem: tProjectItem;
  I: Integer;


begin
  Try
    Result := true;

    for I := 0 to foProject.oProjectItemList.Count - 1 do
    begin
      loProjectItem := tProjectItem(foProject.oProjectItemList.items[I]);



      if loProjectItem.IgnoreItem then
         begin
           foOutput.Log('ProjectItem: '+ loProjectItem.Name + ' Ignored.');

           Continue;
         end;


      case loProjectItem.ProjectItemType of
         pitItem: begin
            foOutput.Log('Project Item: ' + loProjectItem.Name);

            Try
             if foProject.oProjectConfigLoader.Load then
                loProjectItem.templateFile :=
                  tProjectParser.ParseProject(loProjectItem.templateFile, foProject, foOutput);

              if TNovusFileUtils.IsValidFolder(loProjectItem.templateFile) then
               loProjectItem.templateFile := TNovusFileUtils.TrailingBackSlash
                 (loProjectItem.templateFile) + loProjectItem.ItemName;
            Except
              foOutput.LogError('TemplateFile Projectconfig error.');

              Break;
            End;

            if Not FileExists(loProjectItem.templateFile) then
            begin
              foOutput.LogError('template ' + loProjectItem.templateFile +
                ' cannot be found.');

              foOutput.Failed := true;

              Continue;
            end;
         end;
        pitFolder: begin
           loProjectItem.ItemFolder := TNovusFileUtils.TrailingBackSlash(tProjectParser.ParseProject
            (loProjectItem.ItemFolder, foProject, foOutput));

          if not TNovusFileUtils.IsValidFolder(loProjectItem.ItemFolder) then
          begin
            foOutput.LogError('Folder ' + loProjectItem.ItemFolder +
              ' cannot be found.');

            foOutput.Failed := true;

            Continue;
          end;

          loProjectItem.oSourceFiles.Folder := TNovusFileUtils.TrailingBackSlash(
            tProjectParser.ParseProject(loProjectItem.oSourceFiles.Folder, foProject, foOutput));

          if not TNovusFileUtils.IsValidFolder(loProjectItem.oSourceFiles.Folder)
          then
          begin
            foOutput.LogError('Sourcefiles.Folder ' + loProjectItem.oSourceFiles.Folder
              + ' cannot be found.');

            foOutput.Failed := true;

            Continue;
          end;
        end;
      end;

      Try
       if foProject.oProjectConfigLoader.Load then
          loProjectItem.OutputFile := tProjectParser.ParseProject(loProjectItem.OutputFile, foProject, foOutput);

     
      Except
        foOutput.LogError('Output Projectconfig error.');

        Break;
      End;

      if Not DirectoryExists(TNovusStringUtils.JustPathname
        (loProjectItem.OutputFile)) then
      begin
        if not foProject.Createoutputdir then
        begin
          foOutput.LogError('output ' + TNovusStringUtils.JustPathname
            (loProjectItem.OutputFile) + ' directory cannot be found.');

          Continue;
        end
        else
        begin
          if Not ForceDirectories(TNovusStringUtils.JustPathname
            (loProjectItem.OutputFile)) then
          begin
            foOutput.LogError('output ' + TNovusStringUtils.JustPathname
              (loProjectItem.OutputFile) + ' directory cannot be created.');

            Continue;
          end;

        end;
      end;

      if not loProjectItem.deleteoutput then
      begin
        if (not loProjectItem.overrideoutput) and
          FileExists(loProjectItem.OutputFile) then
        begin
          foOutput.Log('output ' + TNovusStringUtils.JustFilename
            (loProjectItem.OutputFile) +
            ' exists - Override Output option off.');

          Continue;
        end;
      end
      else
      begin
        if FileExists(loProjectItem.OutputFile) then
        begin
          foOutput.Log('output ' + TNovusStringUtils.JustFilename
            (loProjectItem.OutputFile) + ' Deleted.');

          TFile.Delete(loProjectItem.OutputFile);
        end;
      end;

      Try
       // if foProject.oProjectConfig.IsLoaded then
          loProjectItem.propertiesFile :=
            tProjectParser.ParseProject(loProjectItem.propertiesFile, foProject, foOutput);
      Except
        foOutput.Log('PropertiesFile Projectconfig error.');

        Break;
      End;

      if loProjectItem.propertiesFile <> '' then
      begin
        if Not FileExists(loProjectItem.propertiesFile) then
        begin
          foOutput.LogError('properties ' + loProjectItem.propertiesFile +
            ' cannot be found.');

          Continue;
        end;
      end;

      If (TNovusFileUtils.IsFileInUse(loProjectItem.OutputFile) = false) or
        (TNovusFileUtils.IsFileReadonly(loProjectItem.OutputFile) = false) then
      begin
        loProjectItem.Execute;
      end
      else
        foOutput.Log('Output: ' + loProjectItem.OutputFile +
          ' is read only or file in use.');
    end;
  Except
    foOutput.InternalError;
    Result := false;
  End;
end;

end.
