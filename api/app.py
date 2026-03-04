from flask import Flask, request, jsonify
from bs4 import BeautifulSoup
from io import BytesIO
from google.cloud import storage
import requests
import base64
import json
import time
import os

app = Flask(__name__)

CANDLESTICK_OPENAI_API_KEY = os.environ.get("CANDLESTICK_OPENAI_API_KEY")
RIZZ_OPENAI_API_KEY = os.environ.get("RIZZ_OPENAI_API_KEY")
PERPLEXITY_API_KEY = os.environ.get("PERPLEXITY_API_KEY")

ALPHA_PROMPT_FILE_PATH = "alpha_prompt.txt"
PERPLEXITY_PROMPT_FILE_PATH = "perplexity_prompt.txt"
RIZZ_PROMPT_FILE_PATH = "rizz_prompt.txt"

OPENAI_BASE_URL = "https://api.openai.com/v1/chat/completions"
PERPLEXITY_BASE_URL = "https://api.perplexity.ai/chat/completions"


def get_txt_file(filename):
    bucket_name = "gen_ai_prompts"
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(filename)

    text = blob.download_as_text()
    return text


@app.route("/getChartAnalysis", methods=["POST"])
def get_chart_analysis():
    req_start = time.time()
    try:
        app.logger.info("AlphaAI request received", extra={
            "remote_addr": request.headers.get("X-Forwarded-For", request.remote_addr),
            "user_agent": request.headers.get("User-Agent"),
            "content_length": request.content_length,
        })

        data = request.get_json(silent=True)
        if data is None:
            app.logger.error("JSON parse failed")
            return jsonify({"error": "Invalid JSON"}), 400

        if not data or "base64Image" not in data:
            app.logger.warning("Missing base64Image key")
            return jsonify({"error": "Missing 'base64Image'"}), 400

        base64_image = data["base64Image"]

        trading_styles = data.get("tradingStyles", ["Swing Trading"])
        risk = data.get("risk", "Medium")
        experience = data.get("experience", "Intermediate")

        app.logger.info("Parsed request", extra={
            "styles": trading_styles,
            "risk": risk,
            "experience": experience,
            "image_size": len(base64_image),
        })

        system_prompt = data.get("prompt", "")
        if not system_prompt:
            app.logger.info("No prompt in request, falling back to GCS bucket")
            system_prompt = get_txt_file(ALPHA_PROMPT_FILE_PATH)

        user_prompt = f"User trading style(s): {trading_styles}.\nUser risk preference: {risk}.\nUser experience: {experience}.\nINSTRUCTIONS: {system_prompt}"
        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": user_prompt
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{base64_image}",
                            "detail": "high"
                        }
                    }
                ]
            }
        ]

        payload = {
            "model": "gpt-5-mini-2025-08-07",
            "messages": messages,
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "chart_analysis",
                    "schema": {
                        "type": "object",
                        "properties": {
                            "status": {
                                "type": "boolean",
                                "description": "Indicates if the uploaded image is a trading chart (true) or not (false)"
                            },
                            "result": {
                                "type": "object",
                                "properties": {
                                    "ticker": {
                                        "type": "string",
                                        "description": "Ticker symbol present in input image"
                                    },
                                    "features": {
                                        "type": "object",
                                        "properties": {
                                            "generalTrends": {
                                                "type": "object",
                                                "properties": {
                                                    "trendDirection": {
                                                        "type": "string",
                                                        "enum": ["up", "down", "sideways"]
                                                    },
                                                    "trendStrength": {
                                                        "type": "string",
                                                        "enum": ["weak", "moderate", "strong"]
                                                    },
                                                    "volume": {
                                                        "type": "string",
                                                        "enum": ["low", "medium", "high"]
                                                    },
                                                    "volatility": {
                                                        "type": "string",
                                                        "enum": ["low", "medium", "high"]
                                                    },
                                                    "analysis": {"type": "string"}
                                                },
                                                "required": ["trendDirection", "trendStrength", "volume", "volatility", "analysis"],
                                                "additionalProperties": False
                                            },
                                            "supportResistance": {
                                                "type": "object",
                                                "properties": {
                                                    "supportLevels": {
                                                        "type": "array",
                                                        "items": {"type": "string", "pattern": "^\\d{1,10}(\\.\\d{1,10})?$"},
                                                        "maxItems": 2
                                                    },
                                                    "resistanceLevels": {
                                                        "type": "array",
                                                        "items": {"type": "string", "pattern": "^\\d{1,10}(\\.\\d{1,10})?$"},
                                                        "maxItems": 2
                                                    },
                                                    "analysis": {"type": "string"}
                                                },
                                                "required": ["supportLevels", "resistanceLevels", "analysis"],
                                                "additionalProperties": False
                                            },
                                            "candlestickPatterns": {
                                                "type": "object",
                                                "properties": {
                                                    "recognizedPatterns": {
                                                        "type": "array",
                                                        "items": {
                                                            "type": "object",
                                                            "properties": {
                                                                "patternName": {"type": "string"},
                                                                "analysis": {"type": "string"}
                                                            },
                                                            "required": ["patternName", "analysis"],
                                                            "additionalProperties": False
                                                        }
                                                    }
                                                },
                                                "required": ["recognizedPatterns"],
                                                "additionalProperties": False
                                            },
                                            "indicatorAnalyses": {
                                                "type": "object",
                                                "properties": {
                                                    "selectedIndicators": {
                                                        "type": "array",
                                                        "items": {
                                                            "type": "object",
                                                            "properties": {
                                                                "indicatorName": {"type": "string"},
                                                                "analysis": {"type": "string"}
                                                            },
                                                            "required": ["indicatorName", "analysis"],
                                                            "additionalProperties": False
                                                        }
                                                    }
                                                },
                                                "required": ["selectedIndicators"],
                                                "additionalProperties": False
                                            },
                                            "futureMarketPrediction": {
                                                "type": "object",
                                                "properties": {
                                                    "timeHorizon": {
                                                        "type": "string",
                                                        "enum": ["short_term", "medium_term", "long_term"]
                                                    },
                                                    "analysis": {"type": "string"}
                                                },
                                                "required": ["timeHorizon", "analysis"],
                                                "additionalProperties": False
                                            },
                                            "potentialTradeSetup": {
                                              "type": "object",
                                              "properties": {
                                                "tradeDirection": {
                                                  "type": "string",
                                                  "enum": ["long", "short"],
                                                  "description": "Direction of the proposed trade based on the chart bias"
                                                },
                                                "entryTargetPrice": {
                                                  "type": "string",
                                                   "pattern": "^\\d{1,10}(\\.\\d{1,10})?$",
                                                  "description": "Exact numeric entry price described in the analysis text; must reflect a price visible on the chart, not a placeholder"
                                                },
                                                "stopLossPrice": {
                                                  "type": "string",
                                                  "pattern": "^\\d{1,10}(\\.\\d{1,10})?$",
                                                  "description": "Exact stop-loss level from the analysis text; must reflect a price visible on the chart"
                                                },
                                                "targetPrices": {
                                                  "type": "array",
                                                  "items": {
                                                    "type": "string",
                                                     "pattern": "^\\d{1,10}(\\.\\d{1,10})?$"
                                                  },
                                                  "maxItems": 2,
                                                  "description": "One or two target levels from the analysis text; must correspond to actual price zones mentioned"
                                                },
                                                "analysis": {
                                                  "type": "string",
                                                  "description": "Narrative explanation of the trade setup and reasoning"
                                                }
                                              },
                                              "required": ["tradeDirection", "entryTargetPrice", "stopLossPrice", "targetPrices", "analysis"],
                                              "additionalProperties": False
                                            }
                                        },
                                        "required": [
                                            "generalTrends",
                                            "supportResistance",
                                            "candlestickPatterns",
                                            "indicatorAnalyses",
                                            "futureMarketPrediction",
                                            "potentialTradeSetup"
                                        ],
                                        "additionalProperties": False
                                    }
                                },
                                "required": ["ticker", "features"],
                                "additionalProperties": False
                            }
                        },
                        "required": ["status", "result"],
                        "additionalProperties": False
                    },
                    "strict": True
                },
            },
        }

        openai_start = time.time()
        try:
            response = requests.post(
                OPENAI_BASE_URL,
                json=payload,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {CANDLESTICK_OPENAI_API_KEY}"
                },
                timeout=180,
                allow_redirects=False
            )
        except requests.exceptions.Timeout:
            app.logger.error("OpenAI request timeout", extra={
                "latency_ms": int((time.time() - openai_start) * 1000)
            })
            return jsonify({"error": "OpenAI timeout"}), 504
        except Exception as e:
            app.logger.exception("OpenAI request failed")
            return jsonify({"error": "OpenAI request failed"}), 500


        app.logger.info("OpenAI response", extra={
            "status_code": response.status_code,
            "latency_ms": int((time.time() - openai_start) * 1000)
        })

        if response.status_code != 200:
             # Log full error body
            try:
                err_json = response.json()
            except Exception:
                err_json = response.text

            app.logger.error("OpenAI non-200 response", extra={
                "response_body": err_json
            })

            return jsonify({"error": "OpenAI API error", "details": err_json}), 500

        try:
            openai_json = response.json()
        except Exception:
            app.logger.exception("Failed to parse OpenAI JSON")
            return jsonify({"error": "Invalid JSON from OpenAI"}), 500

        if (
            "choices" not in openai_json or
            not openai_json["choices"] or
            "message" not in openai_json["choices"][0]
        ):
            app.logger.error("OpenAI response missing expected fields", extra={
                "openai_json": openai_json
            })
            return jsonify({"error": "Invalid response format"}), 500

        content_str = openai_json["choices"][0]["message"]["content"]

        try:
            parsed = json.loads(content_str)
        except Exception:
            app.logger.error("OpenAI returned invalid JSON", extra={"raw": content_str})
            return jsonify({"error": "Bad JSON from OpenAI"}), 500

        if not parsed.get("status"):
            app.logger.warning("Image not recognized as a chart")
            return jsonify({"error": "Not a valid trading chart"}), 400

        result = parsed["result"]

        app.logger.info("Chart analysis success", extra={
            "ticker": result.get("ticker"),
            "latency_total_ms": int((time.time() - req_start) * 1000)
        })

        return jsonify(result), 200

    except Exception as e:
        app.logger.exception("Unhandled server error")
        return jsonify({"error": str(e)}), 500


@app.route("/getArticles", methods=["POST"])
def get_articles():
    try:
        data = request.get_json()
        if not data or "userPrompt" not in data:
            return jsonify({"error": "Missing 'userPrompt' in JSON body."}), 400

        user_prompt = data["userPrompt"]
        prompt = data.get("prompt", "")
        if not prompt:
            app.logger.info("No prompt in request, falling back to GCS bucket")
            prompt = get_txt_file(PERPLEXITY_PROMPT_FILE_PATH)

        payload = {
            "model": "sonar",
            "messages": [
                {"role": "system", "content": prompt},
                {"role": "user", "content": user_prompt}
            ],
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "article_response",
                    "schema": {
                        "type": "object",
                        "properties": {
                            "articles": {
                                "type": "array",
                                "description": "List of relevant news articles",
                                "items": {
                                    "type": "object",
                                    "properties": {
                                        "title": {
                                            "type": "string",
                                            "description": "The headline of the news article"
                                        },
                                        "summary": {
                                            "type": "string",
                                            "description": "A brief summary explaining the article's relevance to the chart analysis"
                                        },
                                        "link": {
                                            "type": "string",
                                            "description": "The link to the news article"
                                        }
                                    },
                                    "required": ["title", "summary", "link"],
                                    "additionalProperties": False
                                }
                            }
                        },
                        "required": ["articles"],
                        "additionalProperties": False
                    }
                }
            },
            "temperature": 0.0,
            "top_p": 0.9,
            "return_images": False,
            "return_related_questions": False,
            "search_recency_filter": "month",
            "top_k": 0,
            "stream": False,
            "presence_penalty": 0,
            "frequency_penalty": 1
        }
        headers = {
            "Authorization": f"Bearer {PERPLEXITY_API_KEY}",
            "Content-Type": "application/json"
        }

        response = requests.post(PERPLEXITY_BASE_URL, json=payload, headers=headers, timeout=180)
        if response.status_code != 200:
            return jsonify({"error": "Perplexity API error", "details": response.json()}), 500

        response_json = response.json()
        if ("choices" in response_json and
            isinstance(response_json["choices"], list) and
            len(response_json["choices"]) > 0 and
            "message" in response_json["choices"][0] and
            "content" in response_json["choices"][0]["message"]):

            content_str = response_json["choices"][0]["message"]["content"]

            cleaned_content = content_str.strip()
            cleaned_content = cleaned_content.replace("json", "")
            cleaned_content = cleaned_content.replace("`", "")

            try:
                parsed = json.loads(cleaned_content)
                return jsonify(parsed), 200
            except json.JSONDecodeError:
                return jsonify({
                    "error": "Could not parse JSON from Perplexity response",
                    "raw_content": content_str
                }), 500
        else:
            return jsonify({
                "error": "Invalid response format from Perplexity",
                "raw_response": response_json
            }), 500

    except Exception as e:
        return jsonify({"error": "Server error occurred"}), 500


@app.route("/getResponses", methods=["POST"])
def generate_response():
    try:
        data = request.get_json()
        if not data or "base64Image" not in data:
            return jsonify({"error": "Missing 'base64Image' in request JSON."}), 400

        description = data["description"]
        name = data["name"]
        base64_image = data["base64Image"]

        rizz_prompt = get_txt_file(RIZZ_PROMPT_FILE_PATH)

        if len(name) > 0:
            rizz_prompt += f"\nBelow is user's description of their situationship:\n{description} with {name}"
        else:
            rizz_prompt += f"\nBelow is user's description of their situationship:\n{description}"

        payload = {
            "model": "gpt-5-mini-2025-08-07",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": rizz_prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}",
                                "detail": "high"
                            }
                        }
                    ]
                }
            ],
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "decode_situationship",
                    "schema": {
                        "type": "object",
                        "properties": {
                            "responses": {
                                "type": "array",
                                "description": "List of exactly 4 categorized convo responses",
                                "items": {
                                    "type": "object",
                                        "properties": {
                                            "text": {
                                                "type": "string",
                                                "description": "Text message response pulled from the conversation"
                                            },
                                            "category": {
                                                "type": "string",
                                                "enum": ["rizz", "nsfw", "romantic", "end it"],
                                                "description": "Category that best describes the tone or intent of the response"
                                            }
                                        },
                                        "required": ["text", "category"],
                                        "additionalProperties": False
                                }
                            },
                            "interestLevel": {
                                "type": "number",
                                "description": "Score from 0 to 10 indicating how interested the other person seems based on message tone, effort, and engagement"
                            },
                            "breakdown": {
                                "type": "string",
                                "description": "Analyze the screenshot and user input describing the situationship. Identify emotional cues, contradictions, message tone, ghosting patterns, power dynamics, or mismatched effort. Summarize what’s really going on in a concise paragraph and give a direct recommendation (e.g., keep going, cut it off, call it out, etc.)."
                            },
                            "redFlags": {
                                "type": "string",
                                "description": "A 3–4 sentence summary highlighting the most concerning behaviors or signals in the conversation, such as breadcrumbing, lovebombing, mixed signals, emotional unavailability"
                            },
                            "greenFlags": {
                                "type": "string",
                                "description": "A 3–4 sentence summary highlighting positive behaviors in the conversation, such as signs of real interest, emotional availability, consistency"
                            }
                        },
                        "required": ["responses", "interestLevel", "breakdown", "redFlags", "greenFlags"],
                        "additionalProperties": False
                    },
                    "strict": True
                }
            }
        }

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {RIZZ_OPENAI_API_KEY}"
        }

        resp = requests.post(OPENAI_BASE_URL, json=payload, headers=headers, timeout=180)
        if resp.status_code != 200:
            return jsonify({"error": resp.json()}), 500

        response_data = resp.json()
        if (
            "choices" in response_data and
            len(response_data["choices"]) > 0 and
            "message" in response_data["choices"][0] and
            "content" in response_data["choices"][0]["message"]
        ):
            raw_content = response_data["choices"][0]["message"]["content"]

            try:
                parsed_responses = json.loads(raw_content)
                return jsonify(parsed_responses), 200
            except json.JSONDecodeError:
                return jsonify({
                    "error": "Could not parse JSON from model response",
                    "raw_content": raw_content
                }), 500
        else:
            return jsonify({
                "error": "Invalid structure in response",
                "response_data": response_data
            }), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/getPoopAnalysis", methods=["POST"])
def get_poop_analysis():
    try:
        data = request.get_json()
        if not data or "health_profile" not in data:
            return jsonify({"error": "Missing 'health_profile' in request JSON."}), 400

        health_profile = data["health_profile"]

        # System prompt with stool analyst persona + tone
        system_prompt = """
        You are a professional stool analyst.
        Your role is to evaluate stool health in a way that is medically insightful
        but written with a playful, personable tone.
        You should react with personality (as if commenting on an interesting finding)
        while still providing clear health context and practical recommendations.
        Keep the analysis short (2–3 sentences), never alarming, and always encouraging.
        """

        payload = {
            "model": "gpt-5-mini-2025-08-07",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Health profile: {json.dumps(health_profile)}"}
            ],
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "poop_analysis",
                    "schema": {
                        "type": "object",
                        "properties": {
                            "poop_score": {
                                "type": "number",
                                "description": "Overall stool health score (0–100)",
                                "minimum": 0,
                                "maximum": 100
                            },
                            "consistency": {
                                "type": "string",
                                "description": "Texture of stool",
                                "enum": ["watery", "loose", "normal", "firm", "hard"]
                            },
                            "color": {
                                "type": "string",
                                "description": "Stool color",
                                "enum": ["lightBrown", "mediumBrown", "darkBrown", "green", "yellow", "black", "red"]
                            },
                            "size": {
                                "type": "string",
                                "description": "Relative stool size",
                                "enum": ["small", "medium", "large"]
                            },
                            "shape": {
                                "type": "string",
                                "description": "Stool shape based on Bristol Stool Chart (types 1–7)",
                                "enum": [
                                    "separateHardLumps",   # Type 1
                                    "lumpySausage",        # Type 2
                                    "crackedSausage",      # Type 3
                                    "smoothSausage",       # Type 4
                                    "softBlobs",           # Type 5
                                    "fluffyPieces",        # Type 6
                                    "watery"               # Type 7
                                ]
                            },
                            "containsBlood": {
                                "type": "boolean",
                                "description": "Whether stool contains visible blood"
                            },
                            "containsFoodParticles": {
                                "type": "boolean",
                                "description": "Whether stool contains visible food particles"
                            },
                            "containsMucus": {
                                "type": "boolean",
                                "description": "Whether stool contains visible mucus"
                            },
                            "hydration_signals": {
                                "type": "string",
                                "description": "What stool suggests about hydration"
                            },
                            "diet_signals": {
                                "type": "string",
                                "description": "What stool suggests about diet/nutrition"
                            },
                            "analysis": {
                                "type": "string",
                                "description": "Stool analyst’s playful but insightful take (2–3 sentences). React with personality, then give clear health context and recommendation."
                            }
                        },
                        "required": [
                            "poop_score",
                            "consistency",
                            "color",
                            "size",
                            "shape",
                            "containsBlood",
                            "containsFoodParticles",
                            "containsMucus",
                            "hydration_signals",
                            "diet_signals",
                            "analysis"
                        ],
                        "additionalProperties": False
                    },
                    "strict": True
                }

            }
        }

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {OPENAI_API_KEY}"
        }

        resp = requests.post(OPENAI_BASE_URL, json=payload, headers=headers, timeout=180)
        if resp.status_code != 200:
            return jsonify({"error": resp.json()}), 500

        response_data = resp.json()
        if (
            "choices" in response_data and
            len(response_data["choices"]) > 0 and
            "message" in response_data["choices"][0] and
            "content" in response_data["choices"][0]["message"]
        ):
            raw_content = response_data["choices"][0]["message"]["content"]

            try:
                parsed_responses = json.loads(raw_content)
                return jsonify(parsed_responses), 200
            except json.JSONDecodeError:
                return jsonify({
                    "error": "Could not parse JSON from model response",
                    "raw_content": raw_content
                }), 500
        else:
            return jsonify({
                "error": "Invalid structure in response",
                "response_data": response_data
            }), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
