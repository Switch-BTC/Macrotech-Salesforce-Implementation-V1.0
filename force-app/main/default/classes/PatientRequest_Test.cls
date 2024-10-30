@IsTest
public class PatientRequest_Test {
    @IsTest
    static void testParameterizedConstructor() {
        // Instantiate using parameterized constructor
        PatientRequest pr = new PatientRequest(
            1, // CentroId
            '123456789', // Cedula
            2, // TipoIdentidadId
            'John', // Nombres
            'Doe', // ApellidoPaterno
            'Smith', // ApellidoMaterno
            '2023-01-01T00:00:00Z', // FechaIngreso
            '1990-01-01', // FechaNac
            'No comments', // Comentarios
            3, // TipoTepapia
            'user1', // User
            'password1' // Password
        );

        // Call toJson() method
        String jsonOutput = pr.toJson();
        System.debug('JSON Output (Parameterized Constructor): ' + jsonOutput);

        // Assertions to verify that the JSON output contains the expected values
        System.assert(jsonOutput.contains('"CentroId":1'), 'JSON should contain CentroId');
        System.assert(jsonOutput.contains('"Cedula":"123456789"'), 'JSON should contain Cedula');
        System.assert(jsonOutput.contains('"TipoIdentidadId":2'), 'JSON should contain TipoIdentidadId');
        System.assert(jsonOutput.contains('"Nombres":"John"'), 'JSON should contain Nombres');
        System.assert(jsonOutput.contains('"ApellidoPaterno":"Doe"'), 'JSON should contain ApellidoPaterno');
        System.assert(jsonOutput.contains('"ApellidoMaterno":"Smith"'), 'JSON should contain ApellidoMaterno');
        System.assert(jsonOutput.contains('"FechaIngreso":"2023-01-01T00:00:00Z"'), 'JSON should contain FechaIngreso');
        System.assert(jsonOutput.contains('"FechaNac":"1990-01-01"'), 'JSON should contain FechaNac');
        System.assert(jsonOutput.contains('"Comentarios":"No comments"'), 'JSON should contain Comentarios');
        System.assert(jsonOutput.contains('"TipoTepapia":3'), 'JSON should contain TipoTepapia');
        System.assert(jsonOutput.contains('"User":"user1"'), 'JSON should contain User');
        System.assert(jsonOutput.contains('"Password":"password1"'), 'JSON should contain Password');
    }

    @IsTest
    static void testNoArgumentConstructor() {
        // Instantiate using no-argument constructor
        PatientRequest pr = new PatientRequest();

        // Set properties
        pr.CentroId = 1;
        pr.Cedula = '123456789';
        pr.TipoIdentidadId = 2;
        pr.Nombres = 'John';
        pr.ApellidoPaterno = 'Doe';
        pr.ApellidoMaterno = 'Smith';
        pr.FechaIngreso = '2023-01-01T00:00:00Z';
        pr.FechaNac = '1990-01-01';
        pr.Comentarios = 'No comments';
        pr.TipoTepapia = 3;
        pr.User = 'user1';
        pr.Password = 'password1';

        // Call toJson() method
        String jsonOutput = pr.toJson();
        System.debug('JSON Output (No-Argument Constructor): ' + jsonOutput);

        // Assertions to verify that the JSON output contains the expected values
        System.assert(jsonOutput.contains('"CentroId":1'), 'JSON should contain CentroId');
        System.assert(jsonOutput.contains('"Cedula":"123456789"'), 'JSON should contain Cedula');
        System.assert(jsonOutput.contains('"TipoIdentidadId":2'), 'JSON should contain TipoIdentidadId');
        System.assert(jsonOutput.contains('"Nombres":"John"'), 'JSON should contain Nombres');
        System.assert(jsonOutput.contains('"ApellidoPaterno":"Doe"'), 'JSON should contain ApellidoPaterno');
        System.assert(jsonOutput.contains('"ApellidoMaterno":"Smith"'), 'JSON should contain ApellidoMaterno');
        System.assert(jsonOutput.contains('"FechaIngreso":"2023-01-01T00:00:00Z"'), 'JSON should contain FechaIngreso');
        System.assert(jsonOutput.contains('"FechaNac":"1990-01-01"'), 'JSON should contain FechaNac');
        System.assert(jsonOutput.contains('"Comentarios":"No comments"'), 'JSON should contain Comentarios');
        System.assert(jsonOutput.contains('"TipoTepapia":3'), 'JSON should contain TipoTepapia');
        System.assert(jsonOutput.contains('"User":"user1"'), 'JSON should contain User');
        System.assert(jsonOutput.contains('"Password":"password1"'), 'JSON should contain Password');
    }
}