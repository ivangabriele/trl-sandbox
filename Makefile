.PHONY: test precommit common_tests slow_tests test_examples tests_gpu

check_dirs := examples tests trl

ACCELERATE_CONFIG_PATH = `pwd`/examples/accelerate_configs
COMMAND_FILES_PATH = `pwd`/commands

test:
	pytest -n auto -m "not slow and not low-priority" -s -v --reruns 5 --reruns-delay 1 --only-rerun '(OSError|Timeout|HTTPError.*502|HTTPError.*504||not less than or equal to 0.01)' tests/

precommit:
	python scripts/add_copyrights.py
	pre-commit run --all-files

slow_tests:
	pytest -m "slow" tests/ $(if $(IS_GITHUB_CI),--report-log "slow_tests.log",)

test_examples:
	touch temp_results_sft_tests.txt
	for file in $(ACCELERATE_CONFIG_PATH)/*.yaml; do \
		TRL_ACCELERATE_CONFIG=$${file} bash $(COMMAND_FILES_PATH)/run_sft.sh; \
		echo $$?','$${file} >> temp_results_sft_tests.txt; \
	done

	touch temp_results_dpo_tests.txt
	for file in $(ACCELERATE_CONFIG_PATH)/*.yaml; do \
		TRL_ACCELERATE_CONFIG=$${file} bash $(COMMAND_FILES_PATH)/run_dpo.sh; \
		echo $$?','$${file} >> temp_results_dpo_tests.txt; \
	done

# ------------------------------------------------------------------------------

run_rm_1:
	python examples/scripts/reward_modeling.py \
		--model_name_or_path Qwen/Qwen2-0.5B-Instruct \
		--dataset_name trl-lib/ultrafeedback_binarized \
		--output_dir Qwen2-0.5B-Reward \
		--per_device_train_batch_size 8 \
		--num_train_epochs 1 \
		--gradient_checkpointing True \
		--learning_rate 1.0e-5 \
		--logging_steps 25 \
		--eval_strategy steps \
		--eval_steps 50 \
		--max_length 2048

run_rm_2:
	python examples/scripts/reward_modeling.py \
		--model_name_or_path Qwen/Qwen2-0.5B-Instruct \
		--dataset_name trl-lib/ultrafeedback_binarized \
		--output_dir Qwen2-0.5B-Reward-LoRA \
		--per_device_train_batch_size 8 \
		--num_train_epochs 1 \
		--gradient_checkpointing True \
		--learning_rate 1.0e-4 \
		--logging_steps 25 \
		--eval_strategy steps \
		--eval_steps 50 \
		--max_length 2048 \
		--use_peft \
		--lora_r 32 \
		--lora_alpha 16

run_ppo_1:
	python -i examples/scripts/ppo/ppo.py \
		--dataset_name trl-internal-testing/descriptiveness-sentiment-trl-style \
		--dataset_train_split descriptiveness \
		--learning_rate 3e-6 \
		--output_dir models/minimal/ppo \
		--per_device_train_batch_size 64 \
		--gradient_accumulation_steps 1 \
		--total_episodes 10000 \
		--model_name_or_path EleutherAI/pythia-1b-deduped \
		--missing_eos_penalty 1.0

run_ppo_2:
	accelerate launch --config_file examples/accelerate_configs/deepspeed_zero3.yaml \
		examples/scripts/ppo/ppo.py \
		--dataset_name trl-internal-testing/descriptiveness-sentiment-trl-style \
		--dataset_train_split descriptiveness \
		--output_dir models/minimal/ppo \
		--num_ppo_epochs 1 \
		--num_mini_batches 1 \
		--learning_rate 3e-6 \
		--per_device_train_batch_size 1 \
		--gradient_accumulation_steps 16 \
		--total_episodes 10000 \
		--model_name_or_path EleutherAI/pythia-1b-deduped \
		--sft_model_path EleutherAI/pythia-1b-deduped \
		--reward_model_path EleutherAI/pythia-1b-deduped \
		--local_rollout_forward_batch_size 1 \
		--missing_eos_penalty 1.0
