function a = shearfoce(p, st)
    % Compare a uniform-strain truss reference with the discrete bar sum.
    % The original code relates this reference to the 2019 single-crack Eq. 12.
    % The state solver uses actual bar intersections, not this reference.

    if p.nBars == 0
        referenceForce = 0;
    else
        % 1. Convert the bar forces into strains using the original expression.
        barStrain = st.barForce / (p.Ef * p.Af);
        strainSum = 0;
        for bar = 1:numel(barStrain)
            strainSum = strainSum + barStrain(bar);
        end
        meanStrain = strainSum / numel(barStrain);

        % 2. Keep the original truss formula and multiplication order.
        referenceForce = p.nsmFaces * p.Af * p.Ef * meanStrain ...
            * p.crackHeight / p.nsmSpacing ...
            * (1 / tan(p.theta) + 1 / tan(p.alpha)) * sin(p.alpha);
    end

    % 3. Preserve all original output fields.
    a.uniformStrainTrussReference_N = referenceForce;
    a.discreteIntersectionSum_N = st.Vnsm;
    a.usedByStateSolver = false;
    a.note = 'Truss reference only; actual bar intersections and two-sided anchorage govern the model.';
end
