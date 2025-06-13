function result = is_vector_in_matrix(matrix, vector)
%IS_VECTOR_IN_MATRIX Checks if a vector is present in a matrix.
%   RESULT = IS_VECTOR_IN_MATRIX(MATRIX, VECTOR) checks if a given vector
%   is present in a matrix. It returns true if the vector is found in the
%   matrix, and false otherwise.
%
%   Inputs:
%       - matrix: The matrix to search in.
%       - vector: The vector to search for.
%
%   Output:
%       - result: A logical value indicating if the vector is present in
%                 the matrix (true) or not (false).
%
%   Example:
%       % Example usage
%       matrix = [1 2 3; 4 5 6; 7 8 9];
%       vector = [4 5 6];
%       result = is_vector_in_matrix(matrix, vector);
%       disp(result);  % Output: true

    result = false;
    for i = 1:size(matrix, 1)
        if isequal(matrix(i, :), vector)
            result = true;
            break;
        end
    end
end