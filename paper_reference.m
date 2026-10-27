function a = paper_reference(p, st)
    % Return the shear reference used in the saved snapshot.
    % This function performs no interpolation or equilibrium calculation.
    a = shearfoce(p, st);
end
