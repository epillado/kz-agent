import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;

public class IfxMuestra {
    private static final int CERTS = 5;
    private static final int MAX_PDF = 2_000_000;
    private static final int MAX_TOTAL = 8_000_000;

    public static void main(String[] args) throws Exception {
        String password = System.getenv("INFORMIX_PWD");
        Class.forName("com.informix.jdbc.IfxDriver");
        Properties props = new Properties();
        props.setProperty("user", "usrtlcg3");
        props.setProperty("password", password);
        String url = "jdbc:informix-sqli://10.100.30.134:1527/tlcg3:INFORMIXSERVER=pse4_dsa";
        StringBuilder sql = new StringBuilder();
        sql.append("BEGIN;\n");
        sql.append("DELETE FROM mercancia_otra_instancia WHERE mercancia_id IN (")
                .append("SELECT m.id FROM mercancia m JOIN certificado c ON c.id = m.certificado_id ")
                .append("WHERE c.observaciones LIKE 'MUESTRA-M9%');\n");
        sql.append("DELETE FROM factura_amparada WHERE certificado_id IN (")
                .append("SELECT id FROM certificado WHERE observaciones LIKE 'MUESTRA-M9%');\n");
        sql.append("DELETE FROM certificado_documento WHERE certificado_id IN (")
                .append("SELECT id FROM certificado WHERE observaciones LIKE 'MUESTRA-M9%');\n");
        sql.append("DELETE FROM mercancia WHERE certificado_id IN (")
                .append("SELECT id FROM certificado WHERE observaciones LIKE 'MUESTRA-M9%');\n");
        sql.append("DELETE FROM productor WHERE certificado_id IN (")
                .append("SELECT id FROM certificado WHERE observaciones LIKE 'MUESTRA-M9%');\n");
        sql.append("DELETE FROM certificado WHERE observaciones LIKE 'MUESTRA-M9%';\n");

        int aceptados = 0;
        int bytes = 0;
        int revisados = 0;
        List<String> folios = new ArrayList<>();
        try (Connection connection = DriverManager.getConnection(url, props)) {
            connection.setReadOnly(true);
            Map<Integer, String> unidades = map(connection, "SELECT idum, unidad FROM cat_um");
            Map<Integer, String> criterios = map(connection, "SELECT idcri, indice FROM cat_cripref");
            Map<Integer, String> vcr = map(connection, "SELECT idcontregional, descripcion FROM cat_contenidoregional");
            String candidatos = "SELECT FIRST 40 anio, solicitud FROM solcuestionarios "
                    + "WHERE idproducexp = 1 AND cancelado = '0' "
                    + "AND EXISTS (SELECT 1 FROM archivog3 a WHERE a.anio = solcuestionarios.anio "
                    + "AND a.solicitud = solcuestionarios.solicitud) "
                    + "ORDER BY anio DESC, solicitud DESC";
            try (Statement statement = connection.createStatement();
                 ResultSet keys = statement.executeQuery(candidatos)) {
                while (keys.next() && aceptados < CERTS && bytes < MAX_TOTAL) {
                    revisados++;
                    int anio = keys.getInt(1);
                    int solicitud = keys.getInt(2);
                    Certificado cert = leer(connection, anio, solicitud, unidades, criterios, vcr);
                    if (cert == null) {
                        continue;
                    }
                    if (bytes + cert.pdf.length > MAX_TOTAL) {
                        continue;
                    }
                    bytes += cert.pdf.length;
                    aceptados++;
                    folios.add(cert.folio);
                    sql.append(cert.sql);
                    System.out.println("OK " + anio + "-" + solicitud + " folio_len=" + cert.folio.length()
                            + " pdf=" + cert.pdf.length + " mercancias=" + cert.mercancias
                            + " productores=" + cert.productores);
                }
            }
        }
        sql.append("COMMIT;\n");
        if (aceptados != CERTS) {
            System.err.println("incompleta aceptados=" + aceptados + " revisados=" + revisados);
            System.exit(4);
        }
        java.nio.file.Files.write(java.nio.file.Path.of("/tmp/muestra-m9.sql"),
                sql.toString().getBytes(StandardCharsets.UTF_8));
        System.out.println("LISTO aceptados=" + aceptados + " revisados=" + revisados + " pdf_bytes=" + bytes);
        System.out.println("FOLIOS " + String.join(" ", folios));
    }

    private static Map<Integer, String> map(Connection connection, String query) throws Exception {
        Map<Integer, String> values = new LinkedHashMap<>();
        try (Statement statement = connection.createStatement();
             ResultSet rows = statement.executeQuery(query)) {
            while (rows.next()) {
                values.put(rows.getInt(1), text(rows.getString(2)));
            }
        }
        return values;
    }

    private static Certificado leer(Connection connection, int anio, int solicitud,
                                    Map<Integer, String> unidades, Map<Integer, String> criterios,
                                    Map<Integer, String> vcr) throws Exception {
        String header = "SELECT firma, nombreexportador, calleexportador, ciudadexportador, paisexportador, "
                + "telexportador, regexportador, nombreimportador, calleimportador, ciudadimportador, "
                + "paisimportador, telimportador, regimportador, nombre, empresa, cargo, telefono, fecha, "
                + "razonsocial, domicilio, pais FROM solcuestionarios WHERE anio = ? AND solicitud = ?";
        String folio;
        String rfc;
        String modalidad;
        UUID certificadoId = UUID.randomUUID();
        StringBuilder body = new StringBuilder();
        try (PreparedStatement statement = connection.prepareStatement(header)) {
            statement.setInt(1, anio);
            statement.setInt(2, solicitud);
            try (ResultSet row = statement.executeQuery()) {
                if (!row.next()) {
                    return null;
                }
                folio = text(row.getString("firma"));
                if (folio.isEmpty() || folio.length() > 40) {
                    return null;
                }
                rfc = text(row.getString("regexportador"));
                String nombreExp = text(row.getString("nombreexportador"));
                String calleExp = text(row.getString("calleexportador"));
                String ciudadExp = text(row.getString("ciudadexportador"));
                String paisExp = text(row.getString("paisexportador"));
                String nombreImp = text(row.getString("nombreimportador"));
                String calleImp = text(row.getString("calleimportador"));
                String ciudadImp = text(row.getString("ciudadimportador"));
                String paisImp = text(row.getString("paisimportador"));
                String regImp = text(row.getString("regimportador"));
                String firmante = text(row.getString("nombre"));
                String empresa = text(row.getString("empresa"));
                String cargo = text(row.getString("cargo"));
                Date fecha = row.getDate("fecha");
                if (rfc.isEmpty() || nombreExp.isEmpty() || calleExp.isEmpty() || ciudadExp.isEmpty()
                        || paisExp.isEmpty() || nombreImp.isEmpty() || calleImp.isEmpty() || ciudadImp.isEmpty()
                        || paisImp.isEmpty() || regImp.isEmpty() || firmante.isEmpty() || empresa.isEmpty()
                        || cargo.isEmpty() || fecha == null) {
                    return null;
                }
                String tercerRazon = blankToNull(row.getString("razonsocial"));
                String tercerDom = blankToNull(row.getString("domicilio"));
                String tercerPais = blankToNull(row.getString("pais"));
                boolean tercer = tercerRazon != null || tercerDom != null || tercerPais != null;
                if (tercer && (tercerRazon == null || tercerDom == null || tercerPais == null)) {
                    return null;
                }
                List<String> productores = productores(connection, anio, solicitud, certificadoId);
                if (productores.isEmpty()) {
                    // MISMO no lleva fila: Certificado.validar rechaza productor en esa modalidad.
                    modalidad = "MISMO";
                } else {
                    modalidad = "DIVERSOS";
                }
                body.append("INSERT INTO certificado (id, numero_unico, estado, exportador_rfc, exp_nombre, ")
                        .append("exp_calle_numero, exp_ciudad, exp_pais, exp_telefono, imp_nombre, imp_calle_numero, ")
                        .append("imp_ciudad, imp_pais, imp_telefono, imp_registro_fiscal, modalidad_productor, ")
                        .append("decl_firmante, decl_empresa, decl_cargo, decl_telefono, observaciones, ")
                        .append("tercer_razon_social, tercer_domicilio, tercer_pais, fecha_firma) VALUES (")
                        .append(q(certificadoId.toString())).append(", ")
                        .append(q(folio)).append(", 'DEFINITIVO', ")
                        .append(q(cut(rfc, 13))).append(", ")
                        .append(q(cut(nombreExp, 200))).append(", ")
                        .append(q(cut(calleExp, 200))).append(", ")
                        .append(q(cut(ciudadExp, 100))).append(", ")
                        .append(q(cut(paisExp, 60))).append(", ")
                        .append(nullable(cut(text(row.getString("telexportador")), 30))).append(", ")
                        .append(q(cut(nombreImp, 200))).append(", ")
                        .append(q(cut(calleImp, 200))).append(", ")
                        .append(q(cut(ciudadImp, 100))).append(", ")
                        .append(q(cut(paisImp, 60))).append(", ")
                        .append(nullable(cut(text(row.getString("telimportador")), 30))).append(", ")
                        .append(q(cut(regImp, 30))).append(", ")
                        .append(q(modalidad)).append(", ")
                        .append(q(cut(firmante, 200))).append(", ")
                        .append(q(cut(empresa, 200))).append(", ")
                        .append(q(cut(cargo, 100))).append(", ")
                        .append(nullable(cut(text(row.getString("telefono")), 30))).append(", ")
                        .append(q("MUESTRA-M9 " + anio + "-" + solicitud)).append(", ")
                        .append(nullable(cut(tercerRazon, 200))).append(", ")
                        .append(nullable(cut(tercerDom, 300))).append(", ")
                        .append(nullable(cut(tercerPais, 60))).append(", ")
                        .append(q(fecha.toString() + " 12:00:00-06")).append(");\n");
                for (String productor : productores) {
                    body.append(productor);
                }
                int mercancias = mercancias(connection, anio, solicitud, certificadoId, rfc, unidades, criterios, vcr, body);
                if (mercancias == 0) {
                    return null;
                }
                byte[] pdf = pdf(connection, anio, solicitud);
                if (pdf == null || pdf.length == 0 || pdf.length > MAX_PDF || !esPdf(pdf)) {
                    return null;
                }
                String sha = sha256(pdf);
                body.append("INSERT INTO certificado_documento (certificado_id, pdf, pdf_sha256, sello_ciudad, ")
                        .append("sello_pais, sello_fecha, sello_funcionario, sello_firma) VALUES (")
                        .append(q(certificadoId.toString())).append(", decode('").append(hex(pdf))
                        .append("','hex'), ").append(q(sha)).append(", ")
                        .append(q(cut(ciudadExp, 100))).append(", ")
                        .append(q(cut(paisExp, 60))).append(", ")
                        .append(q(fecha.toString() + " 12:00:00-06")).append(", ")
                        .append(q(cut(firmante, 200))).append(", ")
                        .append(q(cut(folio, 128))).append(");\n");
                Certificado cert = new Certificado();
                cert.folio = folio;
                cert.pdf = pdf;
                cert.sql = body.toString();
                cert.mercancias = mercancias;
                cert.productores = productores.size();
                return cert;
            }
        }
    }

    private static List<String> productores(Connection connection, int anio, int solicitud, UUID certificadoId) throws Exception {
        List<String> rows = new ArrayList<>();
        String query = "SELECT consecutivo, nombreproductor, calleproductor, ciudadproductor, paisproductor, "
                + "telproductor, regproductor FROM solproductor WHERE anio = ? AND solicitud = ? "
                + "ORDER BY consecutivo";
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setInt(1, anio);
            statement.setInt(2, solicitud);
            try (ResultSet row = statement.executeQuery()) {
                int orden = 1;
                while (row.next()) {
                    String nombre = text(row.getString(2));
                    String calle = text(row.getString(3));
                    String ciudad = text(row.getString(4));
                    String pais = text(row.getString(5));
                    String registro = text(row.getString(7));
                    if (nombre.isEmpty() || calle.isEmpty() || ciudad.isEmpty() || pais.isEmpty() || registro.isEmpty()) {
                        continue;
                    }
                    rows.add(productorSql(certificadoId, orden++, nombre, calle, ciudad, pais, text(row.getString(6)), registro));
                }
            }
        }
        return rows;
    }

    private static String productorSql(UUID certificadoId, int orden, String nombre, String calle, String ciudad,
                                        String pais, String telefono, String registro) {
        String id = certificadoId == null ? "__CERT__" : q(certificadoId.toString());
        return "INSERT INTO productor (id, certificado_id, orden, nombre, calle_numero, ciudad, pais, telefono, "
                + "registro_fiscal) VALUES (" + q(UUID.randomUUID().toString()) + ", " + id + ", " + orden + ", "
                + q(cut(nombre, 200)) + ", " + q(cut(calle, 200)) + ", " + q(cut(ciudad, 100)) + ", "
                + q(cut(pais, 60)) + ", " + nullable(cut(telefono, 30)) + ", " + q(cut(registro, 30)) + ");\n";
    }

    private static int mercancias(Connection connection, int anio, int solicitud, UUID certificadoId, String rfc,
                                  Map<Integer, String> unidades, Map<Integer, String> criterios,
                                  Map<Integer, String> vcr, StringBuilder body) throws Exception {
        String query = "SELECT consecutivo, numerofactura, fechafactura, cod, numeroserie, denominacion, "
                + "cantidad, valor, idum, otraum, idcri, idcontregional, dmi, mai, acu, bmf "
                + "FROM mercancias WHERE anio = ? AND solicitud = ? ORDER BY consecutivo";
        int count = 0;
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setInt(1, anio);
            statement.setInt(2, solicitud);
            try (ResultSet row = statement.executeQuery()) {
                while (row.next()) {
                    String factura = text(row.getString(2));
                    Date fechaFactura = row.getDate(3);
                    String fraccion = text(row.getString(4));
                    String descripcion = text(clob(row, 6));
                    String cantidad = numero(row.getString(7));
                    String valor = numero(row.getString(8));
                    int idUm = row.getInt(9);
                    String unidad = row.wasNull() ? null : unidades.get(idUm);
                    int idCri = row.getInt(11);
                    String criterio = row.wasNull() ? null : criterios.get(idCri);
                    int idVcr = row.getInt(12);
                    String trato = row.wasNull() ? null : vcr.get(idVcr);
                    if (factura.isEmpty() || fechaFactura == null || fraccion.isEmpty() || descripcion.isEmpty()
                            || cantidad == null || valor == null || unidad == null || criterio == null
                            || trato == null || !criterio.matches("[A-G]") || !(trato.equals("VT") || trato.equals("NO"))) {
                        continue;
                    }
                    UUID mercanciaId = UUID.randomUUID();
                    boolean regla = fraccion.length() >= 8;
                    body.append("INSERT INTO mercancia (id, certificado_id, orden, factura_numero, factura_fecha, ")
                            .append("fraccion, regla_especifica_origen, descripcion, numero_serie, cantidad, ")
                            .append("valor_miles_usd, unidad_medida, otra_unidad_medida, criterio_trato, vcr) VALUES (")
                            .append(q(mercanciaId.toString())).append(", ").append(q(certificadoId.toString()))
                            .append(", ").append(row.getInt(1)).append(", ").append(q(cut(factura, 50))).append(", ")
                            .append(q(fechaFactura.toString())).append(", ").append(q(cut(fraccion, 10))).append(", ")
                            .append(regla).append(", ").append(q(cut(descripcion, 1000))).append(", ")
                            .append(nullable(cut(text(row.getString(5)), 100))).append(", ").append(cantidad)
                            .append(", ").append(valor).append(", ").append(q(cut(unidad, 30))).append(", ")
                            .append(nullable(cut(text(row.getString(10)), 60))).append(", ").append(q(criterio))
                            .append(", ").append(q(trato)).append(");\n");
                    body.append("INSERT INTO factura_amparada (exportador_rfc, factura_numero, factura_fecha, ")
                            .append("factura_anio, certificado_id) VALUES (").append(q(cut(rfc, 13))).append(", ")
                            .append(q(cut(factura, 50))).append(", ").append(q(fechaFactura.toString())).append(", ")
                            .append(fechaFactura.toLocalDate().getYear()).append(", ")
                            .append(q(certificadoId.toString())).append(") ON CONFLICT DO NOTHING;\n");
                    for (String codigo : instancias(row)) {
                        body.append("INSERT INTO mercancia_otra_instancia (mercancia_id, codigo) VALUES (")
                                .append(q(mercanciaId.toString())).append(", ").append(q(codigo)).append(");\n");
                    }
                    count++;
                }
            }
        }
        return count;
    }

    private static List<String> instancias(ResultSet row) throws Exception {
        List<String> codes = new ArrayList<>();
        String[] names = {"DMI", "MAI", "ACU", "BMF"};
        for (int i = 0; i < names.length; i++) {
            String value = text(row.getString(13 + i));
            if (value.equals("1") || value.equalsIgnoreCase("S") || value.equalsIgnoreCase("Y")) {
                codes.add(names[i]);
            }
        }
        return codes;
    }

    private static byte[] pdf(Connection connection, int anio, int solicitud) throws Exception {
        String query = "SELECT archivo FROM archivog3 WHERE anio = ? AND solicitud = ?";
        try (PreparedStatement statement = connection.prepareStatement(query)) {
            statement.setInt(1, anio);
            statement.setInt(2, solicitud);
            try (ResultSet row = statement.executeQuery()) {
                if (!row.next()) {
                    return null;
                }
                InputStream input = row.getBinaryStream(1);
                if (input == null) {
                    return null;
                }
                ByteArrayOutputStream out = new ByteArrayOutputStream();
                byte[] buffer = new byte[8192];
                int total = 0;
                int read;
                while ((read = input.read(buffer)) >= 0) {
                    total += read;
                    if (total > MAX_PDF) {
                        return null;
                    }
                    out.write(buffer, 0, read);
                }
                return out.toByteArray();
            }
        }
    }

    private static boolean esPdf(byte[] pdf) {
        return pdf.length > 4 && pdf[0] == '%' && pdf[1] == 'P' && pdf[2] == 'D' && pdf[3] == 'F';
    }

    private static String sha256(byte[] data) throws Exception {
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(data);
        StringBuilder hex = new StringBuilder();
        for (byte piece : digest) {
            hex.append(String.format("%02x", piece));
        }
        return hex.toString();
    }

    private static String hex(byte[] data) {
        StringBuilder hex = new StringBuilder(data.length * 2);
        for (byte piece : data) {
            hex.append(String.format("%02x", piece));
        }
        return hex.toString();
    }

    private static String clob(ResultSet row, int index) throws Exception {
        try {
            return row.getString(index);
        } catch (Exception exception) {
            InputStream input = row.getAsciiStream(index);
            if (input == null) {
                return "";
            }
            return new String(input.readAllBytes(), StandardCharsets.ISO_8859_1);
        }
    }

    private static String numero(String raw) {
        if (raw == null) {
            return null;
        }
        String value = raw.trim();
        if (value.isEmpty()) {
            return null;
        }
        try {
            double parsed = Double.parseDouble(value.replace(",", ""));
            if (!(parsed > 0)) {
                return null;
            }
            return String.format(Locale.US, "%.4f", parsed);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private static String text(String value) {
        return value == null ? "" : value.trim();
    }

    private static String blankToNull(String value) {
        String trimmed = text(value);
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static String cut(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }

    private static String q(String value) {
        return "'" + value.replace("'", "''") + "'";
    }

    private static String nullable(String value) {
        return value == null || value.isEmpty() ? "NULL" : q(value);
    }

    private static final class Certificado {
        String folio;
        byte[] pdf;
        String sql;
        int mercancias;
        int productores;
    }
}
