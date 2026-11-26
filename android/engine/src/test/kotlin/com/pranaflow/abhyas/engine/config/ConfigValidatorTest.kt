package com.pranaflow.abhyas.engine.config

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ConfigValidatorTest {

    @Test
    fun `seedConfig passes ConfigValidator schema and safety invariants`() {
        val result = ConfigValidator.validateJson(SeedConfig.SEED_JSON)
        assertTrue("Expected seedConfig to pass validation, errors=${result.errors}", result.isValid)
        assertNotNull(result.parsedConfig)
        val config = result.parsedConfig!!
        assertEquals("0.1.0", config.configVersion)
        assertEquals(7, config.levels.size)
        assertEquals("Prarambha", config.levels[0].name)
        assertEquals("self", config.levels[0].gate)
        assertEquals("Abhyasa", config.levels[1].name)
        assertEquals("Antar", config.levels[2].name)
        assertEquals("advisory", config.levels[2].gate)
        assertFalse(config.levels[2].requiresTeacherApproval)
        assertEquals("Dhyana", config.levels[6].name)
        assertEquals("advisory", config.levels[6].gate)
    }

    @Test
    fun `getLevel retrieves correct level by id and null otherwise`() {
        val config = SeedConfig.defaultConfig
        val level3 = config.getLevel(3)
        assertNotNull(level3)
        assertEquals("Antar", level3?.name)
        assertTrue(level3?.bandhas?.contains("jalandhara") == true)
        assertNull(config.getLevel(99))
    }

    @Test
    fun `AC-5 rejects bahya hold exceeding antar hold in ratio ladder`() {
        val badJson = SeedConfig.SEED_JSON.replace(
            """[1, 2, 2, 0], [1, 3, 2, 0], [1, 4, 2, 0]""",
            """[1, 2, 2, 4]""",
        )
        val result = ConfigValidator.validateJson(badJson)
        assertFalse(result.isValid)
        assertTrue(result.errors.any { it.contains("Bahya hold") && it.contains("SR-05") })
    }

    @Test
    fun `rejects bahya hold exceeding antar hold in ratio_cap_default`() {
        val badJson = SeedConfig.SEED_JSON.replace(
            """[6, 24, 12, 0]""",
            """[6, 12, 12, 16]""",
        )
        val result = ConfigValidator.validateJson(badJson)
        assertFalse(result.isValid)
        assertTrue(result.errors.any { it.contains("SR-05") })
    }

    @Test
    fun `accepts advisory or self gates on level 3+ and rejects unknown gates`() {
        val selfGateJson = SeedConfig.SEED_JSON.replace(
            """"id": 3,
      "name": "Antar",
      "gate": "advisory",""",
            """"id": 3,
      "name": "Antar",
      "gate": "self",""",
        )
        assertTrue(ConfigValidator.validateJson(selfGateJson).isValid)

        val unknownGateJson = SeedConfig.SEED_JSON.replace(
            """"id": 3,
      "name": "Antar",
      "gate": "advisory",""",
            """"id": 3,
      "name": "Antar",
      "gate": "invalid_gate",""",
        )
        assertFalse(ConfigValidator.validateJson(unknownGateJson).isValid)
    }

    @Test
    fun `rejects missing or out of bounds hold_cap_fraction_of_cht`() {
        val zeroCap = SeedConfig.SEED_JSON.replace(""""hold_cap_fraction_of_cht": 0.6""", """"hold_cap_fraction_of_cht": 0.0""")
        assertFalse(ConfigValidator.validateJson(zeroCap).isValid)

        val overCap = SeedConfig.SEED_JSON.replace(""""hold_cap_fraction_of_cht": 0.6""", """"hold_cap_fraction_of_cht": 1.2""")
        assertFalse(ConfigValidator.validateJson(overCap).isValid)

        val missingCap = SeedConfig.SEED_JSON.replace(""""hold_cap_fraction_of_cht": 0.6,""", "")
        assertFalse(ConfigValidator.validateJson(missingCap).isValid)
    }

    @Test
    fun `rejects malformed JSON and invalid weaning arrays`() {
        assertFalse(ConfigValidator.validateJson("{not json").isValid)
        val badWeaning = SeedConfig.SEED_JSON.replace("[3, 3, 3, 3, 0]", "[3, 3]")
        assertFalse(ConfigValidator.validateJson(badWeaning).isValid)
    }
}
