/*******************************************************************************
 * COPYRIGHT Ericsson 2023 - 2024
 *
 *
 *
 * The copyright to the computer program(s) herein is the property of
 *
 * Ericsson Inc. The programs may be used and/or copied only with written
 *
 * permission from Ericsson Inc. or in accordance with the terms and
 *
 * conditions stipulated in the agreement/contract under which the
 *
 * program(s) have been supplied.
 ******************************************************************************/

package com.ericsson.oss.apps.autoapps.devutils;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Arrays;
import java.util.List;

public class FileUtils {
    private static final List<String> FILEPATHS = Arrays.asList(
            "vulnerability-reports\\",
            "");

    /**
     * @return file from default filepath
     */
    public static File getFile(final String fileName) {
        return FILEPATHS
                .parallelStream()
                .map(s -> s + fileName)
                .map(File::new)
                .peek(f -> System.out.println(f.getAbsolutePath()))
                .filter(File::exists)
                .findFirst().orElseThrow(() -> new RuntimeException(new FileNotFoundException(fileName)));
    }
}