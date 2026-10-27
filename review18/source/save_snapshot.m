function v = save_snapshot(p, st, memory)
    % Arrange a response snapshot in memory for plotting and export.
    % This function does not write a file or change the fatigue history.
    if nargin < 3
        memory = st.memory;
    end

    % 1. Count the available anchor nodes before creating the table.
    numberOfRows = 0;
    for bar = 1:p.nBars
        if isempty(st.fields{bar})
            continue
        end
        for side = 1:2
            numberOfRows = numberOfRows + numel(st.fields{bar}.sides{side}.x);
        end
    end
    rows = zeros(numberOfRows, 12);

    % 2. Fill one row for each bar, anchor side, and node.
    row = 0;
    for bar = 1:p.nBars
        if isempty(st.fields{bar})
            continue
        end
        for side = 1:2
            anchor = st.fields{bar}.sides{side};
            for node = 1:numel(anchor.x)
                row = row + 1;
                rows(row, 1) = bar;
                rows(row, 2) = side;
                rows(row, 3) = anchor.x(node);
                rows(row, 4) = anchor.slip(node);
                rows(row, 5) = anchor.maxSlip(node);
                rows(row, 6) = anchor.tau(node);
                rows(row, 7) = anchor.tauM(node);
                rows(row, 8) = anchor.force(node);
                rows(row, 9) = anchor.strain(node);
                rows(row, 10) = memory.age{bar, side}(node);
                rows(row, 11) = anchor.zone(node);
                rows(row, 12) = memory.failedFRP(bar);
            end
        end
    end

    % 3. Keep the existing steel geometry columns, then append responses.
    numberOfSteel = size(p.steel, 1);
    numberOfGeometryColumns = size(p.steel, 2);
    steel = zeros(numberOfSteel, numberOfGeometryColumns + 3);
    for stirrup = 1:numberOfSteel
        for column = 1:numberOfGeometryColumns
            steel(stirrup, column) = p.steel(stirrup, column);
        end
        steel(stirrup, numberOfGeometryColumns + 1) = st.steelStrain(stirrup);
        steel(stirrup, numberOfGeometryColumns + 2) = st.steelStress(stirrup);
        steel(stirrup, numberOfGeometryColumns + 3) = memory.steelDamage(stirrup);
    end

    % 4. Assign output fields separately, preserving names and order.
    v.NSMfields = rows;
    v.columns = {'bar', 'side', 'x_mm', 'slip_mm', 'maxSlip_mm', ...
        'bondStress_MPa', 'peakBondStress_MPa', 'axialForce_N', ...
        'FRPstrain', 'localCycles', 'zone', 'barFailed'};
    v.steel = steel;
    v.crack = crack_deformation(p, st.q);
end