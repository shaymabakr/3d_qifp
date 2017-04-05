function [c] = configuration() 
    references = {
        struct( ...
        'type', 'article', ...
        'fields', struct( ...
            'author', {'Hakon Wadell'}, ...
            'title', 'Volume, Shape, and Roundness of Quartz Particles', ...
            'journal', 'The Jouurnal of Geology', ...
            'volume', '43', ...
            'number', '3', ...
            'pages', '250-280', ...
            'year', '1935', ...
            'doi', '10.1086/624298', ...
            'URL', 'http://dx.doi.org/10.1086/624298', ...
            'eprint', 'http://dx.doi.org/10.1086/624298', ...
            'abstract', ['The article deals with methods of measuring ' ...
                        'the volume, shape, and roundness of ' ...
                        'sedimentary quartz particles.'] ...
        ) ...
    )};
    
    c.configArray = {
        struct( ...
            'name', 'featureName', ...
            'value', 'Sphericity' ...
        )
        struct( ...
            'name', 'reference', ...
            'value', references ...
        )
        struct( ...
            'name', 'functionToRun', ...
            'value', 'run' ...
        )
    };

    c.inputArray = { 
        struct( ...
            'name', 'featureRootName', ...
            'required', true, ...
            'default', 'sphericity' ...
        ) 
        struct( ...
            'name', 'segmentationVOI', ...
            'required', true, ...
            'internal', true ...
        )
        struct( ...
            'name', 'infoVOI', ...
            'required', true, ...
            'internal', true ...
        ) 
    };
end