
parameters.TE = headerAndExtraData.te;
parameters.no_unwrapped_output = ~algorParam.unwrap.isSaveUnwrappedEcho;
parameters.calculate_B0 = true;
parameters.mag = headerAndExtraData.magn;
parameters.phase_offset_correction = 'bipolar';
parameters.mask = mask;
parameters.voxel_size = voxelSize; % for MCPC-3D-S phase offset smoothing
parameters.output_dir = fullfile(tempdir, 'romeo_tmp');
mkdir(parameters.output_dir);

[unwrapped, B0] = ROMEO(wrappedField, parameters);