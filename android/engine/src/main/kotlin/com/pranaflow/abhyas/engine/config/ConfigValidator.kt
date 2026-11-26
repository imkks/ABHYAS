package com.pranaflow.abhyas.engine.config

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject

data class ConfigValidationResult(
    val isValid: Boolean,
    val errors: List<String>,
    val parsedConfig: PracticeConfig? = null,
)

/**
 * Validates practice configurations against the SRS Section 8 JSON schema and invariants.
 * Rejects configs that omit required fields/caps or allow bahya > antar retention.
 */
object ConfigValidator {
    private val allowedGates = setOf("self", "advisory", "streak", "teacher", "guru_only")
    private val requiredRootKeys = listOf(
        "config_version",
        "matra_default_seconds",
        "hold_cap_fraction_of_cht",
        "comfort_streak_required_for_step",
        "vishrama_days_per_week",
        "levels",
        "weaning",
    )

    private val jsonParser = Json {
        ignoreUnknownKeys = true
        isLenient = false
    }

    fun validateJson(rawJson: String): ConfigValidationResult {
        val rootElement: JsonElement = try {
            jsonParser.parseToJsonElement(rawJson)
        } catch (e: Exception) {
            return ConfigValidationResult(
                isValid = false,
                errors = listOf("Invalid JSON syntax: ${e.message}"),
            )
        }

        val rootObj = rootElement as? JsonObject
            ?: return ConfigValidationResult(
                isValid = false,
                errors = listOf("Root config must be a JSON object"),
            )

        return validate(rootObj)
    }

    fun validate(rootObj: JsonObject): ConfigValidationResult {
        val errors = mutableListOf<String>()

        for (key in requiredRootKeys) {
            if (!rootObj.containsKey(key)) {
                errors += "Config Validation Error: Missing required field '$key'"
            }
        }
        if (errors.isNotEmpty()) {
            return ConfigValidationResult(isValid = false, errors = errors)
        }

        val configVersion = rootObj["config_version"]?.asNonBlankString()
        if (configVersion == null) {
            errors += "Config Validation Error: 'config_version' must be a non-empty string"
        }

        val matraDefault = rootObj["matra_default_seconds"]?.asDoubleValue()
        if (matraDefault == null || matraDefault <= 0.0 || matraDefault > 5.0) {
            errors += "Safety Invariant Violation: 'matra_default_seconds' must be within (0.0, 5.0]"
        }

        val holdCapFraction = rootObj["hold_cap_fraction_of_cht"]?.asDoubleValue()
        if (holdCapFraction == null || holdCapFraction <= 0.0 || holdCapFraction > 1.0) {
            errors += "Safety Invariant Violation: 'hold_cap_fraction_of_cht' must be within (0.0, 1.0]"
        }

        val comfortStreak = rootObj["comfort_streak_required_for_step"]?.asIntValue()
        if (comfortStreak == null || comfortStreak < 1) {
            errors += "Config Validation Error: 'comfort_streak_required_for_step' must be an integer >= 1"
        }

        val vishramaDays = rootObj["vishrama_days_per_week"]?.asIntValue()
        if (vishramaDays == null || vishramaDays < 0 || vishramaDays > 7) {
            errors += "Config Validation Error: 'vishrama_days_per_week' must be an integer in [0, 7]"
        }

        val levelsArray = (rootObj["levels"] as? JsonArray)
        if (levelsArray == null || levelsArray.isEmpty()) {
            errors += "Config Validation Error: 'levels' must be a non-empty array"
        } else {
            validateLevels(levelsArray, errors)
        }

        val weaningObj = rootObj["weaning"] as? JsonObject
        if (weaningObj == null) {
            errors += "Config Validation Error: 'weaning' must be an object"
        } else {
            validateWeaning(weaningObj, errors)
        }

        if (errors.isNotEmpty()) {
            return ConfigValidationResult(isValid = false, errors = errors)
        }

        val parsed = try {
            jsonParser.decodeFromJsonElement(PracticeConfig.serializer(), rootObj)
        } catch (e: Exception) {
            return ConfigValidationResult(
                isValid = false,
                errors = listOf("Deserialization failure: ${e.message}"),
            )
        }

        return ConfigValidationResult(
            isValid = true,
            errors = emptyList(),
            parsedConfig = parsed,
        )
    }

    private fun validateLevels(levelsArray: JsonArray, errors: MutableList<String>) {
        val seenIds = mutableSetOf<Int>()

        for ((idx, item) in levelsArray.withIndex()) {
            val levelObj = item as? JsonObject
            if (levelObj == null) {
                errors += "Config Validation Error: levels[$idx] must be an object"
                continue
            }

            for (req in listOf("id", "name", "gate", "practices", "pariksha")) {
                if (!levelObj.containsKey(req)) {
                    errors += "Config Validation Error: levels[$idx] missing required field '$req'"
                }
            }

            val id = levelObj["id"]?.asIntValue()
            if (id == null || id < 1) {
                errors += "Config Validation Error: levels[$idx].id must be a positive integer"
            } else if (!seenIds.add(id)) {
                errors += "Config Validation Error: duplicate level id $id"
            }

            val name = levelObj["name"]?.asNonBlankString()
            if (name == null) {
                errors += "Config Validation Error: levels[$idx].name must be a non-empty string"
            }

            val gate = levelObj["gate"]?.asNonBlankString()
            if (gate == null || gate !in allowedGates) {
                errors += "Config Validation Error: levels[$idx].gate must be one of $allowedGates"
            }

            val practices = levelObj["practices"] as? JsonArray
            if (practices == null) {
                errors += "Config Validation Error: levels[$idx].practices must be an array"
            }

            val pariksha = levelObj["pariksha"] as? JsonObject
            if (pariksha == null) {
                errors += "Config Validation Error: levels[$idx].pariksha must be an object"
            }

            val baseCount = levelObj["base_count"]
            if (baseCount != null) {
                val baseVal = baseCount.asIntValue()
                if (baseVal == null || baseVal <= 0) {
                    errors += "Config Validation Error: levels[$idx].base_count must be > 0"
                }
            }

            val enforceBahyaInvariant = levelObj["bahya_never_exceeds_antar"]?.asBooleanValue() ?: true

            val ratioLadder = levelObj["ratio_ladder"]
            if (ratioLadder != null) {
                val ladderArr = ratioLadder as? JsonArray
                if (ladderArr == null) {
                    errors += "Config Validation Error: levels[$idx].ratio_ladder must be an array"
                } else {
                    for ((rIdx, ratioElem) in ladderArr.withIndex()) {
                        validateRatioTuple(
                            tuple = ratioElem,
                            label = "level ${id ?: idx} ratio_ladder[$rIdx]",
                            enforceBahyaInvariant = enforceBahyaInvariant,
                            errors = errors,
                        )
                    }
                }
            }

            val ratioCap = levelObj["ratio_cap_default"]
            if (ratioCap != null) {
                validateRatioTuple(
                    tuple = ratioCap,
                    label = "level ${id ?: idx} ratio_cap_default",
                    enforceBahyaInvariant = enforceBahyaInvariant,
                    errors = errors,
                )
            }
        }
    }

    private fun validateRatioTuple(
        tuple: JsonElement,
        label: String,
        enforceBahyaInvariant: Boolean,
        errors: MutableList<String>,
    ) {
        val arr = tuple as? JsonArray
        if (arr == null || arr.size != 4) {
            errors += "Config Validation Error: $label must be a 4-element numeric array [puraka, antar, rechaka, bahya]"
            return
        }
        val values = arr.map { it.asDoubleValue() }
        if (values.any { it == null || it < 0.0 }) {
            errors += "Config Validation Error: $label must contain non-negative numbers"
            return
        }
        val antar = values[1]!!
        val bahya = values[3]!!
        if ((enforceBahyaInvariant || bahya > 0.0) && bahya > antar) {
            errors += "Safety Invariant Violation: Bahya hold ($bahya) exceeds Antar hold ($antar) in $label (SR-05)"
        }
    }

    private fun validateWeaning(weaningObj: JsonObject, errors: MutableList<String>) {
        for (req in listOf("stage_min_weeks", "stage_min_consecutive_sessions", "graduation_consecutive_sessions")) {
            if (!weaningObj.containsKey(req)) {
                errors += "Config Validation Error: weaning missing required field '$req'"
            }
        }

        val weeks = weaningObj["stage_min_weeks"] as? JsonArray
        if (weeks == null || weeks.size != 5 || weeks.any { (it.asIntValue() ?: -1) < 0 }) {
            errors += "Config Validation Error: weaning.stage_min_weeks must contain 5 non-negative integers"
        }

        val sessions = weaningObj["stage_min_consecutive_sessions"] as? JsonArray
        if (sessions == null || sessions.size != 5 || sessions.any { (it.asIntValue() ?: -1) < 0 }) {
            errors += "Config Validation Error: weaning.stage_min_consecutive_sessions must contain 5 non-negative integers"
        }

        val gradSessions = weaningObj["graduation_consecutive_sessions"]?.asIntValue()
        if (gradSessions == null || gradSessions < 1) {
            errors += "Config Validation Error: weaning.graduation_consecutive_sessions must be >= 1"
        }
    }

    private fun JsonElement.asNonBlankString(): String? {
        val primitive = this as? JsonPrimitive ?: return null
        if (!primitive.isString) return null
        return primitive.content.takeIf { it.isNotBlank() }
    }

    private fun JsonElement.asIntValue(): Int? {
        val primitive = this as? JsonPrimitive ?: return null
        if (primitive.isString) return null
        return primitive.intOrNull
    }

    private fun JsonElement.asDoubleValue(): Double? {
        val primitive = this as? JsonPrimitive ?: return null
        if (primitive.isString) return null
        return primitive.doubleOrNull
    }

    private fun JsonElement.asBooleanValue(): Boolean? {
        val primitive = this as? JsonPrimitive ?: return null
        if (primitive.isString) return null
        return primitive.booleanOrNull
    }
}
