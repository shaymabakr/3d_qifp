function [c] = configuration() 
    c.configArray = {
        struct( ...
            'name', 'outputName', ...
            'value', 'Maximum Area Image Output' ...
        )
        struct( ...
            'name', 'reference', ...
            'value', '' ...
        )
        struct( ...
            'name', 'functionToEachOutput', ...
            'value', 'output' ...
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
            'default', [strjoin(strtrim(cellstr(num2str(fix(clock)'))'), '-') ...
                                '-Ax-Cor-Sag-boundary-'] ...
        )
        struct( ...
            'name', 'outputExtension', ...
            'required', true, ...
            'default', 'png'...
        )         
        struct( ...
            'name', 'output', ...
            'required', true, ...
            'internal', true ...
        )       
       struct( ...
            'name', 'each', ...
            'required', true, ...
            'default', true ... 
        )       
        struct( ...
            'name', 'processingUid', ...
            'required', false, ...
            'internal', true, ...
            'default', num2str(now) ...
        )
        struct( ...
            'name', 'windowLevelPreset', ...
            'required', true, ...
            'default', 'ctLung' ...
        )
        struct( ...
            'name', 'intensityVOI', ...
            'required', true, ...
            'internal', true ...
        )
        struct( ...
            'name', 'segmentationVOI', ...
            'required', true, ...
            'internal', true ...
        )
    };

end