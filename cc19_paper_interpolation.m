function a = cc19_paper_interpolation(p, st)
    % Preserve the snapshot interface and reuse the truss reference formula.
    % This comparison does not participate in beam equilibrium.
    a = truss_reference(p, st);
end
