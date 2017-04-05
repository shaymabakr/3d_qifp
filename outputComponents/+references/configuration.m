function [c] = configuration() 
    c.configArray = {
        struct( ...
            'name', 'outputName', ...
            'value', 'Reference Output' ...
        )
        struct( ...
            'name', 'reference', ...
            'value', '' ...
        )
        struct( ...
            'name', 'functionToFinalOutput', ...
            'value', 'finalOutput' ...
        )
    };

    c.inputArray = { 
        struct( ...
            'name', 'outputRoot', ...
            'required', true, ...
            'default', pwd ...
        ) 
        struct( ...
            'name', 'outputFolder', ...
            'required', true, ...
            'default', '/' ...
        )
        struct( ...
            'name', 'outputRootName', ...
            'required', true, ...
            'default', [strjoin(strtrim(cellstr(num2str(fix(clock)'))'),...
                                                    '-')]...
        )
        struct( ...
            'name', 'outputFinalName', ...
            'required', true, ...
            'default', 'references'...
        ) 
        struct( ...
            'name', 'outputExtension', ...
            'required', true, ...
            'default', 'bib'...
        )         
        struct( ...
            'name', 'allConfig', ...
            'required', true, ...
            'internal', true ...
        )       
        struct( ...
            'name', 'final', ...
            'required', true, ...
            'default', true ... 
        )
    };

end