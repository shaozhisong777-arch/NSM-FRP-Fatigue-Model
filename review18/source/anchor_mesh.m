function [x, weights] = anchor_mesh(p, L)
    % Create nodes and trapezoidal integration weights for one anchor side.
    % p.nCells is the number of elements, not the number of nodes.

    if ~isscalar(L) || ~isfinite(L) || L <= 0
        error('cc19:mesh', 'Anchor length must be positive.');
    end

    % Keep linspace to preserve the original equally spaced node positions.
    numberOfElements = p.nCells;
    numberOfNodes = numberOfElements + 1;
    x = linspace(0, L, numberOfNodes)';

    % Calculate each element length separately.
    elementLength = zeros(numberOfElements, 1);
    for element = 1:numberOfElements
        elementLength(element) = x(element + 1) - x(element);
    end

    % Each element gives half its length to each end node.
    weights = zeros(numberOfNodes, 1);
    weights(1) = elementLength(1) / 2;
    for node = 2:numberOfNodes - 1
        weights(node) = (elementLength(node - 1) + elementLength(node)) / 2;
    end
    weights(numberOfNodes) = elementLength(numberOfElements) / 2;
end